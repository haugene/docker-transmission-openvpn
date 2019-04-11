import pandas as pd

df = pd.read_csv('GhostPath_URLS.csv', header=None,
                 names=['country', 'city', 'url'])

df['location'] = (df['country'].map(str) + '-' + df['city']).map(
    lambda x: x.replace(' ', '-'))

urls_by_location = df.groupby('location')['url'].apply(list).reset_index()

tail = """
auth-user-pass /config/openvpn-credentials.txt
client
redirect-gateway
remote-cert-tls server
cipher AES-256-CBC
proto udp
dev tun
nobind
ca /etc/openvpn/ghostpath/ca.crt
"""
def create_cert(row):
    with open(f'{row["location"]}.ovpn', 'w') as f:
        for url in row['url']:
            f.write(f'remote {url} 443 udp\n')
        f.write(tail)

urls_by_location.apply(create_cert, axis=1)
