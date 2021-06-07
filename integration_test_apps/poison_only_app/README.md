# PoisonOnlyApp

This app uses the `airbrake_client` app defined at the root of the git repository.

The app imports `poison`, and not `jason`, to ensure two things:
* Compiling the app without `jason` is successful.
* Encoding with `poison` works just fine.
