#!/usr/bin/env sh

set -e

echo "Updating GeoIP database."

tmpfile=$(mktemp)
tmpdir=$(mktemp -d)

curl -L -o $tmpfile http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz

tar -xzf $tmpfile -C $tmpdir

find $tmpdir -type f -exec mv {} $tmpdir \;

mv $tmpdir/GeoLite2-Country.mmdb $(dirname $0)/Sources/libmaxminddb/

echo "Updated GeoIP database."



