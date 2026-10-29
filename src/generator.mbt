///|
/// Identifiers from a clock and a source of random bytes the caller
/// supplies, keeping what the time-based versions need between calls:
/// version 1 and 6 timestamps never repeat or go back, and version 7 ids
/// made within one millisecond count up, so they sort in the order made.
pub struct Generator {
  priv clock : () -> Int64
  priv random : &@moonrand.Source
  priv mut last_ticks : Int64?
  priv mut last_ticks_v6 : Int64?
  priv mut last_millis : Int64?
  priv mut last_counter : UInt64
}

///|
/// `clock` gives nanoseconds since 1970; `random` is where the random bits
/// come from: `@system.source` from `moonrand/system` in a program, or a
/// `Replay` of fixed bytes in a test that wants the same ids every run.
pub fn Generator::new(
  clock~ : () -> Int64,
  random~ : &@moonrand.Source,
) -> Generator {
  {
    clock,
    random,
    last_ticks: None,
    last_ticks_v6: None,
    last_millis: None,
    last_counter: 0UL,
  }
}

///|
fn Generator::bytes(self : Generator, n : Int32) -> Bytes raise Refused {
  @moonrand.bytes(n, self.random) catch {
    why => raise Random(why)
  }
}

///|
/// A 14-bit clock sequence from the random source.
fn Generator::clock_seq(self : Generator) -> Int32 raise Refused {
  let b = self.bytes(2)
  ((b[0].to_int() << 8) | b[1].to_int()) & 0x3FFF
}

///|
fn next_ticks(now : Int64, last : Int64?) -> Int64 {
  let t = ticks_of(now)
  match last {
    Some(prev) if t <= prev => prev + 1L
    _ => t
  }
}

///|
/// Version 1 with `node`; the clock sequence is random unless given.
pub fn Generator::v1(
  self : Generator,
  node~ : Int64,
  clock_seq? : Int32,
) -> Uuid raise Refused {
  let ticks = next_ticks((self.clock)(), self.last_ticks)
  self.last_ticks = Some(ticks)
  let clock_seq = match clock_seq {
    Some(c) => c
    None => self.clock_seq()
  }
  v1(ticks~, clock_seq~, node~)
}

///|
/// Version 6 with `node`; the clock sequence is random unless given.
pub fn Generator::v6(
  self : Generator,
  node~ : Int64,
  clock_seq? : Int32,
) -> Uuid raise Refused {
  let ticks = next_ticks((self.clock)(), self.last_ticks_v6)
  self.last_ticks_v6 = Some(ticks)
  let clock_seq = match clock_seq {
    Some(c) => c
    None => self.clock_seq()
  }
  v6(ticks~, clock_seq~, node~)
}

///|
/// Version 4 from 16 random bytes.
pub fn Generator::v4(self : Generator) -> Uuid raise Refused {
  v4(self.bytes(16))
}

///|
/// Version 7. Within one millisecond the counter goes up by one with a
/// fresh random tail; when the clock steps back, the millisecond after the
/// last one is used; when the counter runs out, the millisecond moves on.
pub fn Generator::v7(self : Generator) -> Uuid raise Refused {
  let mut millis = (self.clock)() / 1_000_000L
  let (counter, tail) = match self.last_millis {
    Some(prev) if millis <= prev => {
      if millis < prev {
        millis = prev + 1L
      }
      let counter = self.last_counter + 1UL
      if counter > 0x3FFFFFFFFFFUL {
        millis += 1L
        counter_and_tail(self.bytes(10))
      } else {
        let b = self.bytes(4)
        let tail = (b[0].to_uint64() << 24) |
          (b[1].to_uint64() << 16) |
          (b[2].to_uint64() << 8) |
          b[3].to_uint64()
        (counter, tail)
      }
    }
    _ => counter_and_tail(self.bytes(10))
  }
  self.last_millis = Some(millis)
  self.last_counter = counter
  seven(millis.reinterpret_as_uint64(), counter, tail)
}
