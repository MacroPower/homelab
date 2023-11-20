# .flux

This directory contains generated Flux HelmRelease manifests for each application. Mainly this exists so that examples can be easily indexed by tools like [kubesearch](https://kubesearch.dev/).

These files are generated using Jsonnet. To see the real files, look under `applications/base/<name>/`.

## Notes

Adjacent manifests such as Secrets, Ingresses, and such are not included in the HelmRelease manifests.

I do not have any pre-commit hooks for this or anything like that, so it is possible that the generated manifests will be out of date. However, I do try to keep them reasonably current.

The HelmReleases also created from bases only and contain no customization from the overlays. As a result there are a few specific releases that may not work as expected, but the majority should be fine as I try to use reasonable defaults.
