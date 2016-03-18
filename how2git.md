## Setting your identity
Because forgetting to do this can lead to leaking your PC username and/or associated email:
```
> $ git config --global user.name "$username"
> $ git config --global user.email $email
```

To do this for only the current repository, add the following to `.git/config`:
```
[user]
  name = "$username"
  email = $email
```
