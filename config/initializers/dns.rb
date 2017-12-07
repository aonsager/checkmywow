require 'resolv'
Resolv::DefaultResolver.replace_resolvers([
  Resolv::Hosts.new, 
  Resolv::DNS.new(
    nameserver: ['8.8.8.8', '8.8.4.4'], 
    search: ['mydns.com'], 
    ndots: 1
  )
])
require 'resolv-replace'