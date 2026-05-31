name: appimg
on:
  push:
    branches:
      - main
    paths:
      - '**.sh'
      - '**.json'
      - '**.md'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v2
      
    - name: Test appimg script
      run: |
        chmod +x appimg.sh
        ./appimg.sh list