# JasonOnlyApp

This app uses the `airbrake_client` app defined at the root of the git repository.

The app imports `jason`, and not `poison`, to ensure two things:
* Compiling the app without `poison` is successful.
* Encoding with `jason` works just fine.
