You can standardize on a GitHub Actions–based CI/CD that mirrors your spec‑kit flow: feature branches → stage (TestFlight, multi‑device human tests) → manual merge to main for production releases.[1][2]

## Branching and workflow

Use this simple branch model.[3][4]

- **Branches**  
  - main: Always production‑ready, only merged from stage after approved testing.[4][3]
  - stage: Integration branch; all features go here before release, used for TestFlight builds.[1]
  - feature/*: Short‑lived branches created from stage for each spec‑kit task/feature.[5][6]

- **Flow**  
  - spec‑kit defines work → create feature/XYZ from stage.  
  - Local dev: flutter analyze, flutter test, manual device tests.  
  - PR feature/XYZ → stage: CI runs tests + builds Android artifact; optional iOS build without upload.  
  - After QA on stage backend, merge stage → main via PR.  
  - Merge to main triggers production build and TestFlight upload (or App Store release) using Fastlane.[7][8][9]

## How‑to: setup steps

These are the high‑level steps to implement.

- **Repo & spec‑kit**  
  - Keep /spec (or /.specify) with Markdown specs and plan files in the same repo, so each feature branch includes spec changes.[5]
  - Add a CONTRIBUTING.md describing: create feature from stage, reference spec section, run local tests, open PR to stage.

- **Secrets & signing**  
  - GitHub Actions secrets:  
    - ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_ALIAS_PASSWORD.  
    - APP_STORE_CONNECT_API_KEY, APP_STORE_CONNECT_ISSUER_ID, APP_STORE_CONNECT_KEY_ID, MATCH_GIT_PRIVATE_KEY, MATCH_PASSWORD (if using fastlane match).[8][9][7]
  - iOS: configure fastlane lanes in ios/fastlane/Fastfile for build_upload_testflight and release_app.[7][8]

- **Flavors/environments**  
  - Define Flutter flavors dev and stage with separate bundle IDs and backends, e.g. com.vronone.app.stage / com.vronone.app.[10]
  - Wire build ID (e.g. run_number‑short_sha) into an about/settings screen so testers can report exactly which build they use.[10]

## GitHub Actions CI/CD pipeline (flutter‑cicd.yml)

Place this in .github/workflows/flutter‑cicd.yml and adapt names/bundle IDs as needed.[2][10]

```yaml
name: Flutter CI/CD

on:
  push:
    branches:
      - 'feature/*'
      - stage
      - main
  pull_request:
    branches:
      - stage
      - main

env:
  FLUTTER_VERSION: 'stable'
  ANDROID_BUILD_DIR: build/app/outputs/flutter-apk
  IOS_BUILD_DIR: build/ios/ipa

jobs:
  # 1) Fast checks on feature branches
  test-feature:
    if: startsWith(github.ref, 'refs/heads/feature/')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: ${{ env.FLUTTER_VERSION }}
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test

  # 2) Stage: build dev/stage artifacts + optionally upload iOS to TestFlight (internal)
  build-stage:
    if: github.ref == 'refs/heads/stage'
    runs-on: macos-latest
    env:
      BUILD_NUMBER: ${{ github.run_number }}
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: ${{ env.FLUTTER_VERSION }}

      - name: Flutter pub get
        run: flutter pub get

      - name: Run tests
        run: |
          flutter analyze
          flutter test

      # Android stage build (APK / AAB)
      - name: Build Android stage (AAB)
        run: |
          flutter build appbundle \
            --flavor stage \
            --release \
            --dart-define=BUILD_NUMBER=${BUILD_NUMBER}

      - name: Upload Android stage artifact
        uses: actions/upload-artifact@v4
        with:
          name: android-stage-aab
          path: ${{ env.ANDROID_BUILD_DIR }}/*.aab

      # iOS stage build + TestFlight upload via fastlane
      - name: Install Ruby gems
        working-directory: ios
        run: bundle install

      - name: Build & upload iOS stage to TestFlight
        working-directory: ios
        env:
          ASC_KEY_ID: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
          ASC_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
          MATCH_GIT_PRIVATE_KEY: ${{ secrets.MATCH_GIT_PRIVATE_KEY }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          BUILD_NUMBER: ${{ env.BUILD_NUMBER }}
        run: |
          bundle exec fastlane ios build_upload_testflight \
            build_number:${BUILD_NUMBER} \
            flavor:stage

  # 3) Main: production builds + TestFlight (external) or App Store
  build-main:
    if: github.ref == 'refs/heads/main'
    runs-on: macos-latest
    env:
      BUILD_NUMBER: ${{ github.run_number }}
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: ${{ env.FLUTTER_VERSION }}

      - name: Flutter pub get
        run: flutter pub get

      - name: Run tests
        run: |
          flutter analyze
          flutter test

      - name: Build Android prod (AAB)
        run: |
          flutter build appbundle \
            --flavor prod \
            --release \
            --dart-define=BUILD_NUMBER=${BUILD_NUMBER}

      - name: Upload Android prod artifact
        uses: actions/upload-artifact@v4
        with:
          name: android-prod-aab
          path: ${{ env.ANDROID_BUILD_DIR }}/*.aab

      - name: Install Ruby gems
        working-directory: ios
        run: bundle install

      - name: Build & upload iOS prod to TestFlight
        working-directory: ios
        env:
          ASC_KEY_ID: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
          ASC_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
          MATCH_GIT_PRIVATE_KEY: ${{ secrets.MATCH_GIT_PRIVATE_KEY }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          BUILD_NUMBER: ${{ env.BUILD_NUMBER }}
        run: |
          bundle exec fastlane ios build_upload_testflight \
            build_number:${BUILD_NUMBER} \
            flavor:prod
```

The fastlane lane build_upload_testflight would typically call match, build_app with the correct scheme/flavor, and upload_to_testflight.[9][8][7]

## Day‑to‑day usage with spec‑kit

- For each approved spec section, create feature/xyz from stage and commit both code and spec changes.[6][5]
- Use spec‑kit locally to keep spec and implementation aligned while running flutter analyze and flutter test before opening PRs.  
- When QA accepts a TestFlight build from stage, manually merge stage into main via PR; this will create a new production build and TestFlight distribution with a unique build number visible inside the app.[7][10]

If you share your existing fastlane Fastfile or flavor setup, the pipeline can be refined to match your exact bundle IDs and schemes.

[1](https://www.perplexity.ai/search/7dcd306d-9312-406a-8d9e-e8b37e7c00e8)
[2](https://stackoverflow.com/questions/57808152/how-to-build-flutter-in-github-actions-ci-cd)
[3](https://www.geeksforgeeks.org/git/branching-strategies-in-git/)
[4](https://www.gitkraken.com/learn/git/best-practices/git-branch-strategy)
[5](https://www.perplexity.ai/search/e26e5bce-8634-47eb-a9dd-c9f2fa174adf)
[6](https://dev.to/karmpatel/git-branching-strategies-a-comprehensive-guide-24kh)
[7](https://brightinventions.pl/blog/ios-testflight-github-actions-fastlane-match/)
[8](https://stackoverflow.com/questions/79049126/how-to-set-up-fastlane-for-ios-builds-with-github-actions)
[9](https://github.com/fastlane/fastlane/discussions/16890)
[10](https://www.perplexity.ai/search/fe466e9f-e6e8-4182-987d-da12b0ac93a3)
[11](https://www.youtube.com/watch?v=xWQhncyCvPA)
[12](https://www.youtube.com/watch?v=kFgiRPsK6ho)
[13](https://docs.flutter.dev/deployment/cd)