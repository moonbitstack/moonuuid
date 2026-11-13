// The google/uuid side of the cross-implementation check: it prints and reads
// the same tab-separated lines as the library's src/examples/03-interop, so
// scripts/check_interop.py can compare the two.
package main

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"os"
	"strings"

	"github.com/google/uuid"
)

const gregorian = 122192928000000000 // 100ns ticks between 1582-10-15 and 1970

func variantName(v uuid.Variant) string {
	switch v {
	case uuid.Reserved:
		return "Ncs"
	case uuid.RFC4122:
		return "Rfc"
	case uuid.Microsoft:
		return "Microsoft"
	default:
		return "Future"
	}
}

// describe writes one line for one text: the canonical form, the version, the
// variant, the time as this library reads it, the clock sequence and node when
// the version carries them, the bare digits, and the URN.
func describe(text string) string {
	u, err := uuid.Parse(text)
	if err != nil {
		return text + "\t!"
	}
	digits := strings.ReplaceAll(u.String(), "-", "")
	version, variant := "-", variantName(u.Variant())
	timed, fielded := false, false
	if u.Variant() == uuid.RFC4122 {
		version = fmt.Sprint(int(u.Version()))
		timed = u.Version() == 1 || u.Version() == 6 || u.Version() == 7
		fielded = u.Version() == 1 || u.Version() == 6
	}
	stamp := "-"
	if timed {
		stamp = fmt.Sprint(when(u))
	}
	seq, node := "-", "-"
	if fielded {
		seq = fmt.Sprint(u.ClockSequence())
		node = fmt.Sprint(binary.BigEndian.Uint64(append([]byte{0, 0}, u.NodeID()...)))
	}
	return strings.Join([]string{text, u.String(), version, variant, stamp, seq, node, digits, u.URN()}, "\t")
}

// when is the timestamp as RFC 9562 reads the fields: 100-nanosecond intervals
// since 1582 for versions 1 and 6, milliseconds since 1970 for version 7.
func when(u uuid.UUID) uint64 {
	// Time() transposes version 6 correctly only for version 1; for version 6
	// it returns the fields as one big number, version nibble included, so the
	// timestamp is put back together here.
	if u.Version() == 6 {
		raw := binary.BigEndian.Uint64(u[:8])
		return (raw>>32)<<28 | (raw>>16&0xffff)<<12 | raw&0xfff
	}
	ticks := uint64(u.Time())
	if u.Version() == 7 {
		return (ticks - gregorian) / 10000
	}
	return ticks
}

func fromReader(b []byte) uuid.UUID {
	u, err := uuid.NewRandomFromReader(bytes.NewReader(b))
	if err != nil {
		panic(err)
	}
	return u
}

// made prints the identifiers this implementation makes. The ones with a fixed
// input carry the same label as the library's, so the two can be compared
// value for value; the clock-based ones are its own.
func made() []string {
	counting := make([]byte, 16)
	for i := range counting {
		counting[i] = byte(i)
	}
	rows := [][2]string{
		{"v3-dns-www", uuid.NewMD5(uuid.NameSpaceDNS, []byte("www.example.com")).String()},
		{"v5-dns-www", uuid.NewSHA1(uuid.NameSpaceDNS, []byte("www.example.com")).String()},
		{"v5-url-example", uuid.NewSHA1(uuid.NameSpaceURL, []byte("https://example.org/")).String()},
		{"v4-zero", fromReader(make([]byte, 16)).String()},
		{"v4-count", fromReader(counting).String()},
	}
	out := make([]string, 0, len(rows))
	for _, row := range rows {
		out = append(out, row[0]+"\t"+row[1])
	}
	return out
}

// now prints the identifiers this implementation makes from the clock, which
// are different on every run.
func now() []string {
	out := []string{}
	if u, err := uuid.NewUUID(); err == nil {
		out = append(out, "go-v1\t"+u.String())
	}
	if u, err := uuid.NewV6(); err == nil {
		out = append(out, "go-v6\t"+u.String())
	}
	if u, err := uuid.NewV7(); err == nil {
		out = append(out, "go-v7\t"+u.String())
	}
	return out
}

func main() {
	args := os.Args[1:]
	mode := "make"
	if len(args) > 0 {
		mode = args[0]
	}
	switch mode {
	case "read":
		for _, text := range args[1:] {
			fmt.Println(describe(text))
		}
	case "now":
		for _, line := range now() {
			fmt.Println(line)
		}
	default:
		for _, line := range made() {
			fmt.Println(line)
		}
	}
}
