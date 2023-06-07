# iac-intro

This project provides the demo code for the introduction to iac

# Requirements

- Go 1.20
- Terraform 1.4.6

# Secrets
Secrets are similar to inputs except that they are encrypted and only used by GitHub Actions. It's a convenient way to keep sensitive data out of the GitHub Actions workflow YAML file.

* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`

```yaml
  - name: Run Go Tests
    working-directory: test
    run: go test -v -tags=test
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```


# Project structure

The source code for this project lives in `src` which contains the go code
for the lambda. All infrastructure work should be in the `infrastructure`
directory.
