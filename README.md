# check_ssl

Simple script to check SSL certificate dates. Just create a config file called
`check_ssl.cfg` with one host on each line and run

```
$ check_ssl.sh
```

If some certificate will expire soon, it will send an email with the expiring
certificate list. A SSMTP config is needed and must be changed inside the
script.
