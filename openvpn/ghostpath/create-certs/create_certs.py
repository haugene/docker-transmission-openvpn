'''This code reads in "GhostPath_URLS.csv"
(which was copied from https://ghostpath.com/servers)
in order to create basic ovpn files for all the different instances
It requires pandas and python 3.6 or greater.
'''
import pandas as pd

TAIL = '''
auth-user-pass /config/openvpn-credentials.txt
client
redirect-gateway
remote-cert-tls server
cipher AES-256-CBC
proto udp
dev tun
nobind
ca /etc/openvpn/ghostpath/ca.crt
'''


def main():

    # Read in teh CSV
    df = pd.read_csv('GhostPath_URLS.csv', header=None,
                     names=['country', 'city', 'url'])

    # Create a new column `locations` with the stringized file names
    df['location'] = (df['country'].map(str) + '-' + df['city']).map(
        lambda x: x.replace(' ', '-'))

    # Group by locations and create lists of all the urls for each location
    urls_by_location = df.groupby('location')['url'].apply(list).reset_index()

    def create_cert(row):
        '''
        Creates a file with the location name and the urls with the `TAIL`
        '''
        with open(f'{row["location"]}.ovpn', 'w') as f:
            for url in row['url']:
                f.write(f'remote {url} 443 udp\n')
            f.write(TAIL)

    # Save the files for each location
    urls_by_location.apply(create_cert, axis=1)


if __name__ == '__main__':
    main()
