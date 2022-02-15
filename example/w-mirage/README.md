# `w-mirage`

<br>

This example is a simple unikernel which has a front-page and an echo route to
repeat what the user said into the URL. This is a simple example of how to make
a DreamOS with MirageOS. You can find here an explanation about how to deploy
a DreamOS on `gcloud`.

#### Initialization

You must create or use an existing `gcloud` project and enable "billing" on it.
Then, you must get an IP address from `gcloud` and keep it here as `<IP>`. On
the other side, your DNS primary server must have a new record/`<HOSTNAME>` to
point your domain-name to `<IP>` - and, by this way, be able to do the let's
encrypt challenge.

```sh
$ gcloud init
# Your name below must be __globally__ unique, dream-os will be taken by now
$ gcloud projects create dream-os --name="dream-os"
# Enable billing for project
# Go to https://cloud.google.com, log into Console, select project from
#  dropdown, then click billing
$ gcloud config set project dream-os
$ gcloud compute addresses create <HOSTNAME> --region europe-west1
# Set your in your DNS zone file the IP address yielded above
$ gsutil mb gs://dream-os
```

#### Compilation

This example is really simple and for the `gcloud` deployement, you must
compile the MirageOS to `virtio` and make a recognizable image for `gcloud`.
Some arguments are available such as the `port`, the certificate seed and the
account seed for let's encrypt and if you want to make a productive certficate
or not (default to `false`).

DHCP is required when `gcloud` gives to us via this protocol our internal IP
address.

```sh
$ opam install mirage
$ mirage configure -t virtio --dhcp true --hostname <HOSTNAME> --tls true \
  --letsencrypt true --production false
$ make depends
$ mirage build
$ solo5-virtio-mkimage -f tar -- dream.tar.gz dream.virtio
```

#### Deployement

Finally, you can deploy the image, configure the `gcloud` firewall and deploy
an instance of your DreamOS:

```sh
$ gsutil cp dream.tar.gz gs://dream-os
$ gcloud compute images create dream-os --source-uri gs://dream-os/dream.tar.gz
$ gcloud compute firewall-rules create http --allow tcp:80
$ gcloud compute firewall-rules create http --allow tcp:443
$ gcloud compute instances create dream-os --image dream-os --address <IP> \
  --zone europe-west1-b --machine-type f1-micro
```

#### DreamOS locally

MirageOS has several targets and so, several deployements. The most easy one is
the `unix` target which compiles your MirageOS application into a simple
executable:

```sh
$ mirage configure -t unix
$ make depends
$ mirage build
$ ./dream --tls false --port 8080
# or with you want the TLS support via a fake certificate
$ ./dream --tls true --port 4343
```
