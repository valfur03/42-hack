# 42 Hack

Some script to automate tasks on the 42 intra.

## SSH GitLab

This script updates your ssh key in your settings with your local `~/.ssh/id_rsa.pub` key.

```shell
./ssh_gitlab.sh
```

You can add a `--public-key` flag to specify a public key instead of the default one.

```shell
./ssh_gitlab.sh --public-key ~/Desktop/my-public-key
```

