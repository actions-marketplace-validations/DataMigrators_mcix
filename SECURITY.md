# Security Policy

Thank you for helping keep this project and its users safe. This document explains how to report security vulnerabilities.

## Supported Versions

We currently provide security updates for the following versions:

- `main` branch (next unreleased version)
- Latest released minor version (e.g. 2.x)
- Previous minor version (e.g. 1.x) on a best-effort basis

Older versions are considered **out of support** and will not receive security fixes.

## Reporting a Vulnerability

If you believe you have found a security vulnerability, **please do not open a public issue or pull request.**

Instead, use one of these options:

1. **GitHub private vulnerability report**  
   Go to the repository’s **Security → Report a vulnerability** page and submit a private report (preferred, if enabled).

2. **Email**  
   Send an email to: `security@datamigrators.com`  
   Please use an English subject line that includes the word `SECURITY`.

When reporting, include as much detail as possible:

- A clear description of the issue and its potential impact
- Step-by-step instructions to reproduce
- Any proof-of-concept code, logs, or screenshots
- Which versions/commit hashes are affected
- Any known mitigations or workarounds

## Response Timeline

We aim to:

- Acknowledge your report within **3 business days**
- Provide an initial assessment within **7 business days**
- Work with you to validate the issue and prepare a fix
- Coordinate a release and public disclosure once a fix or mitigation is available

These timeframes are goals, not guarantees, but we will do our best and keep you updated.

## Responsible Disclosure

We kindly ask that you:

- Do not publicly disclose the vulnerability until we have had a reasonable opportunity to investigate and release a fix.
- Avoid accessing, modifying, or destroying data that does not belong to you.
- Limit testing to systems and accounts you own or have permission to test.
- Respect applicable laws and regulations during your research.

We will credit you (with your consent) in release notes or advisories when we fix confirmed vulnerabilities.

## Out of Scope

The following are generally out of scope for this policy:

- Best-practice recommendations without a clear security impact
- Denial-of-service attacks relying solely on excessive resource usage
- Vulnerabilities in third-party dependencies that we do not control (though we welcome reports that help us track and update them)
- Issues affecting unsupported versions (see “Supported Versions” above)

If you’re unsure whether something is in scope, please report it anyway — we’d rather hear from you than miss a real issue.
