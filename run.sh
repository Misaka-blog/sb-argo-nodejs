#!/bin/bash

export CLOUDFLARE_TUNNEL_TOKEN='your cloudflare tunnel token'
export CLOUDFLARE_TUNNEL_HOSTNAME='your cloudflare tunnel hostname'
export VLESS_UUID='your vless uuid'
# your vless websocket path
export VLESS_PATH='/misaka'
# your cf ip
export CLOUDFLARE_IP='chinese.com'

curl -L 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64' -o ./cloudflared
chmod +x cloudflared
./cloudflared --version
nohup ./cloudflared --no-autoupdate tunnel run --token "$CLOUDFLARE_TUNNEL_TOKEN" > cloudflared.log 2>&1 &

curl -O -L https://github.com/SagerNet/sing-box/releases/download/v1.8.0/sing-box-1.8.0-linux-amd64.tar.gz
tar -zxf sing-box-1.8.0-linux-amd64.tar.gz

sing-box-1.8.0-linux-amd64/sing-box version

cat <<EOF > sing-box-1.8.0-linux-amd64/config.json
{"log":{"disabled":false,"level":"info","timestamp":true},"dns":{"servers":[{"tag":"cloudflare","address":"https://1.1.1.1/dns-query","strategy":"ipv4_only","detour":"direct"},{"tag":"block","address":"rcode://success"}],"rules":[{"rule_set":["geosite-cn","geosite-category-ads-all"],"server":"block"}],"final":"cloudflare","strategy":"","disable_cache":false,"disable_expire":false},"inbounds":[{"type":"vless","tag":"vless-in","listen":"::","listen_port":8000,"users":[{"name":"misaka","uuid":"$VLESS_UUID","flow":""}],"transport":{"type":"ws","path":"$VLESS_PATH","headers":{},"max_early_data":0,"early_data_header_name":""},"multiplex":{"enabled":true,"padding":false}}],"outbounds":[{"type":"direct","tag":"direct"},{"type":"block","tag":"block"},{"type":"dns","tag":"dns-out"}],"route":{"rules":[{"protocol":"dns","outbound":"dns-out"},{"ip_is_private":true,"outbound":"direct"},{"rule_set":["geoip-cn","geosite-cn","geosite-category-ads-all"],"outbound":"block"}],"rule_set":[{"tag":"geoip-cn","type":"remote","format":"binary","url":"https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs","download_detour":"direct"},{"tag":"geosite-cn","type":"remote","format":"binary","url":"https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-cn.srs","download_detour":"direct"},{"tag":"geosite-category-ads-all","type":"remote","format":"binary","url":"https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs","download_detour":"direct"}],"auto_detect_interface":true,"final":"direct"},"experimental":{"cache_file":{"enabled":true,"path":"cache.db","cache_id":"mycacheid","store_fakeip":true}}}
EOF

echo "vless://$VLESS_UUID@$CLOUDFLARE_IP:443?encryption=none&flow=none&security=tls&sni=$CLOUDFLARE_TUNNEL_HOSTNAME&alpn=h2%2Chttp%2F1.1&fp=chrome&type=ws&host=$CLOUDFLARE_TUNNEL_HOSTNAME&path=$VLESS_PATH#idev"
sing-box-1.8.0-linux-amd64/sing-box run -c sing-box-1.8.0-linux-amd64/config.json