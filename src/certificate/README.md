This directory contains a bogus `localhost` certificate which gets compiled into
the Dream library, to be used as a default certificate for development.

You can review the certificate with:

```
$ openssl x509 -in localhost.crt -text -noout
```

...or generate a new one with:

```
$ bash generate.sh
```

Review output for the current certificate:

```
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            73:70:02:9f:18:34:77:ab:7b:91:5d:b9:19:8c:cb:92:9c:4f:b5:ec
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = US, ST = IL, L = Chicago, O = Dream, OU = Dream, CN = localhost
        Validity
            Not Before: Mar  9 23:04:46 2021 GMT
            Not After : Mar  9 23:04:46 2029 GMT
        Subject: C = US, ST = IL, L = Chicago, O = Dream, OU = Dream, CN = localhost
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:cf:62:1b:5e:05:eb:d7:27:dc:cc:bb:96:9f:08:
                    d1:85:75:d0:f6:db:9b:ca:1a:f7:de:82:a0:09:87:
                    a1:4f:76:8d:ab:54:98:dd:9f:af:c2:25:30:d4:c9:
                    44:14:52:3e:35:f9:3f:20:86:24:57:4e:f9:4b:5a:
                    2c:11:35:0d:4f:f9:52:dc:2d:b2:bd:50:6c:e6:30:
                    df:2a:ba:9e:cc:f9:99:b8:ff:6c:32:94:cd:c1:3f:
                    50:4c:34:bf:43:f2:27:0d:0f:f6:99:49:06:ff:45:
                    b1:2d:0e:f1:4d:c8:22:41:17:62:ec:df:8b:10:01:
                    33:d6:64:53:2e:ac:4a:07:ce:08:f0:be:7a:c8:f8:
                    0c:e9:92:2f:44:66:b8:3e:34:4b:91:f8:3b:d5:1f:
                    64:3d:54:aa:cb:4f:60:aa:4c:be:ef:5f:49:4e:65:
                    22:57:b8:e3:93:56:e7:6d:75:c0:fa:fc:79:14:82:
                    02:35:c3:8c:7a:10:9d:2a:c0:01:df:ab:23:bd:eb:
                    1a:4c:0b:ce:5e:60:19:e0:35:75:6b:cd:a5:6d:c8:
                    55:34:55:b4:fd:05:f4:59:05:96:8d:45:f0:85:24:
                    03:80:72:95:8b:03:f8:24:9a:7a:ca:05:85:d8:55:
                    c1:84:85:90:79:e2:cb:24:05:04:e6:51:31:a7:2b:
                    a8:31
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage:
                Digital Signature, Key Encipherment, Key Agreement
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Subject Alternative Name:
                DNS:localhost
    Signature Algorithm: sha256WithRSAEncryption
         39:2b:14:43:a3:e7:4d:40:c0:4e:44:75:fc:69:2d:7d:71:b1:
         bf:11:94:99:e7:d6:53:7e:ef:84:92:fd:5b:67:d7:a2:6a:f1:
         8d:f5:c7:63:7f:3c:2c:d5:ad:63:77:66:20:1e:66:21:77:fd:
         4f:5d:95:f5:c6:6a:29:42:a6:d0:d4:3c:97:a4:c0:04:83:0d:
         36:f0:ac:a4:ec:1d:62:fc:da:60:46:aa:73:30:6b:af:18:8b:
         ec:ce:d6:de:0c:a8:43:36:6f:bc:2b:f5:26:d3:48:70:38:63:
         bd:69:87:d1:fa:f2:b8:11:b4:f9:50:be:da:30:22:12:aa:3b:
         14:36:f0:ef:7e:81:71:98:ff:65:e9:aa:76:e3:a4:41:f9:af:
         f8:37:51:02:f8:31:c5:fe:ce:ad:6d:e7:4d:3b:91:eb:91:2a:
         38:7f:21:25:14:dd:b0:6e:b6:fa:85:59:47:37:62:bc:16:76:
         00:59:1c:3e:9f:0f:7e:40:3c:e1:dd:04:e3:15:a3:33:51:2b:
         92:ff:ee:86:84:c5:4c:c8:b9:9a:7a:18:9d:42:58:94:9a:13:
         2c:76:1e:08:f4:6a:c4:24:06:a6:07:c3:19:7f:df:f6:4f:05:
         df:63:55:1d:bd:3f:f9:64:eb:76:6a:c7:d6:5a:6e:5b:6c:b7:
         fb:73:dc:c8
```
