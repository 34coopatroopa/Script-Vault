#!/usr/bin/env python3
"""
Network Analysis and Troubleshooting Utility

Provides network diagnostic capabilities including:
- Ping sweeps
- Port scanning
- DNS resolution checks
- Traceroute functionality
"""

import socket
import subprocess
import sys
import argparse
from datetime import datetime
from ipaddress import ip_network

class NetworkAnalyzer:
    def __init__(self):
        self.results = []
    
    def ping_host(self, host, count=4):
        """Ping a host and return results"""
        print(f"Pinging {host}...")
        try:
            if sys.platform.startswith('win'):
                result = subprocess.run(
                    ['ping', '-n', str(count), host],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
            else:
                result = subprocess.run(
                    ['ping', '-c', str(count), host],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
            return result.returncode == 0, result.stdout
        except Exception as e:
            return False, str(e)
    
    def scan_port(self, host, port, timeout=1):
        """Check if a port is open on a host"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(timeout)
            result = sock.connect_ex((host, port))
            sock.close()
            return result == 0
        except Exception as e:
            print(f"Error scanning {host}:{port}: {e}")
            return False
    
    def scan_port_range(self, host, ports, timeout=1):
        """Scan a range of ports on a host"""
        print(f"Scanning {host}...")
        open_ports = []
        
        for port in ports:
            if self.scan_port(host, port, timeout):
                open_ports.append(port)
                print(f"  Port {port} is open")
        
        return open_ports
    
    def ping_sweep(self, network):
        """Ping sweep a network range"""
        print(f"Performing ping sweep on {network}...")
        reachable_hosts = []
        
        for ip in ip_network(network, strict=False).hosts():
            ip_str = str(ip)
            is_reachable, _ = self.ping_host(ip_str, count=1)
            
            if is_reachable:
                reachable_hosts.append(ip_str)
                print(f"  {ip_str} is reachable")
        
        return reachable_hosts
    
    def resolve_dns(self, hostname):
        """Resolve hostname to IP address"""
        try:
            ip = socket.gethostbyname(hostname)
            return ip
        except socket.gaierror:
            return None
    
    def get_report(self):
        """Generate a summary report"""
        report = f"""
# Network Analysis Report
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Summary
- Scans completed: {len(self.results)}
- Hosts reached: {sum(1 for r in self.results if r.get('reachable'))}

## Results
"""
        for result in self.results:
            report += f"- {result}\n"
        
        return report


def main():
    parser = argparse.ArgumentParser(description='Network Analysis Tool')
    parser.add_argument('--ping', help='Host to ping')
    parser.add_argument('--scan', help='Host to scan')
    parser.add_argument('--ports', help='Port range (e.g., 80,443 or 1-1024)')
    parser.add_argument('--sweep', help='Network to sweep (CIDR notation)')
    parser.add_argument('--dns', help='Hostname to resolve')
    parser.add_argument('--output', help='Output file path')
    
    args = parser.parse_args()
    
    analyzer = NetworkAnalyzer()
    
    if args.ping:
        reachable, output = analyzer.ping_host(args.ping)
        print(output)
        analyzer.results.append({'type': 'ping', 'host': args.ping, 'reachable': reachable})
    
    if args.dns:
        ip = analyzer.resolve_dns(args.dns)
        if ip:
            print(f"{args.dns} resolves to {ip}")
        else:
            print(f"Could not resolve {args.dns}")
    
    if args.sweep:
        hosts = analyzer.ping_sweep(args.sweep)
        print(f"\nFound {len(hosts)} reachable hosts")
        analyzer.results.append({'type': 'sweep', 'network': args.sweep, 'hosts': len(hosts)})
    
    if args.scan:
        # Parse port range
        if args.ports:
            if '-' in args.ports:
                start, end = map(int, args.ports.split('-'))
                ports = range(start, end + 1)
            else:
                ports = [int(p) for p in args.ports.split(',')]
            
            open_ports = analyzer.scan_port_range(args.scan, ports)
            print(f"\nOpen ports on {args.scan}: {open_ports}")
            analyzer.results.append({'type': 'scan', 'host': args.scan, 'open_ports': open_ports})
    
    # Generate report
    if args.output:
        report = analyzer.get_report()
        with open(args.output, 'w') as f:
            f.write(report)
        print(f"\nReport saved to {args.output}")


if __name__ == '__main__':
    main()
