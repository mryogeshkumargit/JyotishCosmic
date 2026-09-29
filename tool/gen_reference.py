#!/usr/bin/env python3
"""Generate test/fixtures/swe_reference.json with the Swiss Ephemeris command-line tool (swetest).

Usage: SWETEST=/path/to/swetest SWEPH_EPHE=/path/to/ephe python3 tool/gen_reference.py
The values are used by test/engine_test.dart to verify the app's AstroEngine.
"""
import json, os, subprocess

SWETEST = os.environ.get("SWETEST", "swetest")
EPHE = os.environ.get("SWEPH_EPHE", "")

CHARTS = [
    # name, local date, local time, utc offset, lat, lon
    ("Delhi 1990", (1990, 8, 15), (6, 30), 5.5, 28.6139, 77.2090),
    ("Mumbai 1985", (1985, 1, 26), (23, 45), 5.5, 19.0760, 72.8777),
    ("London 2000", (2000, 1, 1), (12, 0), 0.0, 51.5074, -0.1278),
    ("New York 1975", (1975, 11, 3), (4, 10), -5.0, 40.7128, -74.0060),
    ("Sydney 2010", (2010, 6, 21), (17, 20), 10.0, -33.8688, 151.2093),
]

BODIES = "0123456t"  # Sun Moon Mercury Venus Mars Jupiter Saturn TrueNode
NAMES = ["sun", "moon", "mercury", "venus", "mars", "jupiter", "saturn", "rahu"]


def run(args):
    cmd = [SWETEST] + args + ["-head"]
    if EPHE:
        cmd += ["-eswe", f"-edir{EPHE}"]
    return subprocess.run(cmd, capture_output=True, text=True, check=True).stdout


def jd_greg(y, m, d, hours):
    """Julian Day for a Gregorian date and decimal UT hours (Meeus 7.1)."""
    if m <= 2:
        y -= 1
        m += 12
    a = y // 100
    b = 2 - a + a // 4
    return int(365.25 * (y + 4716)) + int(30.6001 * (m + 1)) + d + b - 1524.5 + hours / 24.0


def julday_ut(date, time, offset):
    y, m, d = date
    hh, mm = time
    return jd_greg(y, m, d, hh + mm / 60 - offset)


def chart(jd, lat, lon, sid, hsys):
    out = run([f"-bj{jd}", "-ut", f"-p{BODIES}", f"-sid{sid}", "-fls", f"-house{lon},{lat},{hsys}"])
    lines = [l.split() for l in out.strip().splitlines()]
    planets = {}
    for name, row in zip(NAMES, lines[:8]):
        planets[name] = {"lon": float(row[0]), "speed": float(row[1])}
    cusps = [float(l[0]) for l in lines[8:20]]
    asc = float(lines[20][0])
    mc = float(lines[21][0])
    return planets, cusps, asc, mc


def ayanamsa(jd, sid):
    out = run([f"-bj{jd}", "-ut", "-p0", f"-sid{sid}", "-fl"])
    sid_sun = float(out.split()[0])
    trop = float(run([f"-bj{jd}", "-ut", "-p0", "-fl"]).split()[0])
    return (trop - sid_sun) % 360


def sunrise_sunset(date, offset, lat, lon):
    y, m, d = date
    # Search from local midnight (as a UT Julian Day).
    start = jd_greg(y, m, d, -offset)
    out = run(["-rise", "-p0", f"-bj{start}", "-ut", f"-geopos{lon},{lat},0", "-n1"])
    parts = out.split()
    # rise  D.MM.YYYY  HH:MM:SS.s  set  D.MM.YYYY  HH:MM:SS.s ...
    def jd_of(dstr, tstr):
        dd, mm, yy = dstr.split(".")
        h, mi, s = tstr.split(":")
        hours = int(h) + int(mi) / 60 + float(s) / 3600
        return jd_greg(int(yy), int(mm), int(dd), hours)
    return jd_of(parts[1], parts[2]), jd_of(parts[4], parts[5])


def main():
    result = []
    for name, date, time, offset, lat, lon in CHARTS:
        jd = julday_ut(date, time, offset)
        planets, whole_cusps, asc, mc = chart(jd, lat, lon, 1, "W")
        _, kp_cusps, kp_asc, _ = chart(jd, lat, lon, 5, "P")
        kp_planets, _, _, _ = chart(jd, lat, lon, 5, "W")
        rise, set_ = sunrise_sunset(date, offset, lat, lon)
        result.append({
            "name": name,
            "date": list(date),
            "time": list(time),
            "utcOffset": offset,
            "lat": lat,
            "lon": lon,
            "jd": jd,
            "ayanamsaLahiri": ayanamsa(jd, 1),
            "planets": planets,
            "ascendant": asc,
            "mc": mc,
            "kpCusps": kp_cusps,
            "kpPlanets": {k: v["lon"] for k, v in kp_planets.items()},
            "sunriseJd": rise,
            "sunsetJd": set_,
        })
    os.makedirs("test/fixtures", exist_ok=True)
    with open("test/fixtures/swe_reference.json", "w") as f:
        json.dump(result, f, indent=1)
    print(f"wrote {len(result)} charts")


if __name__ == "__main__":
    main()
