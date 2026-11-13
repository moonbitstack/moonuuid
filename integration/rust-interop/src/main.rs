//! The `uuid` crate's side of the cross-implementation check: it prints and
//! reads the same tab-separated lines as the library's `src/examples/03-interop`,
//! so `scripts/check_interop.py` can compare the two.

use std::env;
use uuid::timestamp::context::ContextV7;
use uuid::timestamp::Timestamp;
use uuid::{Builder, Uuid};

/// Hundred-nanosecond ticks between 1582-10-15 and 1970-01-01.
const GREGORIAN: u64 = 122_192_928_000_000_000;

fn variant_name(u: &Uuid) -> &'static str {
    match u.get_variant() {
        uuid::Variant::NCS => "Ncs",
        uuid::Variant::RFC4122 => "Rfc",
        uuid::Variant::Microsoft => "Microsoft",
        _ => "Future",
    }
}

/// One line for one text: canonical form, version, variant, the timestamp as
/// RFC 9562 reads it, the clock sequence and node when the version carries
/// them, the bare digits, and the URN.
fn describe(text: &str) -> String {
    let u = match Uuid::parse_str(text) {
        Ok(u) => u,
        Err(_) => return format!("{}\t!", text),
    };
    let rfc = u.get_variant() == uuid::Variant::RFC4122;
    let version = u.get_version_num();
    let fields: Vec<String> = match (rfc, version) {
        (false, _) => vec!["-".into(), variant_name(&u).into(), "-".into(), "-".into(), "-".into()],
        (true, n) => {
            let stamp = u.get_timestamp().map(|ts| match n {
                1 | 6 => ts.to_gregorian().0,
                _ => {
                    let (secs, nanos) = ts.to_unix();
                    secs * 1000 + u64::from(nanos) / 1_000_000
                }
            });
            let (seq, node) = if n == 1 || n == 6 {
                let (_, counter) = u.get_timestamp().unwrap().to_gregorian();
                let node = u.as_bytes()[10..]
                    .iter()
                    .fold(0u64, |all, b| (all << 8) | u64::from(*b));
                (counter.to_string(), node.to_string())
            } else {
                ("-".to_string(), "-".to_string())
            };
            vec![
                n.to_string(),
                variant_name(&u).into(),
                stamp.map_or("-".to_string(), |s| s.to_string()),
                seq,
                node,
            ]
        }
    };
    format!(
        "{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
        text,
        u.hyphenated(),
        fields[0],
        fields[1],
        fields[2],
        fields[3],
        fields[4],
        u.simple(),
        u.urn()
    )
}

/// The identifiers this implementation makes. Those with a fixed input carry
/// the same label as the library's, so the two can be compared value for value.
fn made() -> Vec<(String, Uuid)> {
    let counting: [u8; 16] = std::array::from_fn(|i| i as u8);
    let zero = [0u8; 16];
    let node = [0x9f, 0x6b, 0xde, 0xce, 0xd8, 0x46];
    let gregorian = Timestamp::from_gregorian_time(0x1EC9_414C_232A_B00, 0x33C8);
    vec![
        ("v1-rfc".into(), Uuid::new_v1(gregorian, &node)),
        ("v6-rfc".into(), Uuid::new_v6(gregorian, &node)),
        (
            "v3-dns-www".into(),
            Uuid::new_v3(&Uuid::NAMESPACE_DNS, b"www.example.com"),
        ),
        (
            "v5-dns-www".into(),
            Uuid::new_v5(&Uuid::NAMESPACE_DNS, b"www.example.com"),
        ),
        (
            "v5-url-example".into(),
            Uuid::new_v5(&Uuid::NAMESPACE_URL, b"https://example.org/"),
        ),
        ("v4-zero".into(), Builder::from_random_bytes(zero).into_uuid()),
        ("v4-count".into(), Builder::from_random_bytes(counting).into_uuid()),
        ("v8-count".into(), Uuid::new_v8(counting)),
    ]
}

/// The identifiers this implementation makes from the clock, which are
/// different on every run.
fn now() -> Vec<(String, Uuid)> {
    vec![
        (
            "rust-v7-now".into(),
            Uuid::new_v7(Timestamp::from_unix(ContextV7::new(), 1_645_557_742, 0)),
        ),
        ("rust-v4-now".into(), Uuid::new_v4()),
    ]
}

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();
    let mode = args.first().map_or("make", String::as_str);
    match mode {
        "read" => {
            for text in &args[1..] {
                println!("{}", describe(text));
            }
        }
        "now" => {
            for (label, u) in now() {
                println!("{}\t{}", label, u);
            }
        }
        _ => {
            for (label, u) in made() {
                println!("{}\t{}", label, u);
            }
        }
    }
    let _ = GREGORIAN;
}
