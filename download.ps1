# Copyright (c) Meta Platforms, Inc. and affiliates.
# This software may be used and distributed according to the terms of the Llama 2 Community License Agreement.

# Prompt user to enter the URL from email
$PRESIGNED_URL = Read-Host "Enter the URL from email: "
Write-Host ""

# Prompt user to enter the list of models to download
$MODEL_SIZE = Read-Host "Enter the list of models to download without spaces (7B,13B,70B,7B-chat,13B-chat,70B-chat), or press Enter for all: "
$TARGET_FOLDER = "."  # where all files should end up
New-Item -ItemType Directory -Force -Path $TARGET_FOLDER | Out-Null

if (-not $MODEL_SIZE) {
    $MODEL_SIZE = "7B,13B,70B,7B-chat,13B-chat,70B-chat"
}

Write-Host "Downloading LICENSE and Acceptable Usage Policy"
Invoke-WebRequest -Uri ($PRESIGNED_URL -replace '\*','LICENSE') -OutFile "$TARGET_FOLDER/LICENSE"
Invoke-WebRequest -Uri ($PRESIGNED_URL -replace '\*','USE_POLICY.md') -OutFile "$TARGET_FOLDER/USE_POLICY.md"

Write-Host "Downloading tokenizer"
Invoke-WebRequest -Uri ($PRESIGNED_URL -replace '\*','tokenizer.model') -OutFile "$TARGET_FOLDER/tokenizer.model"
Invoke-WebRequest -Uri ($PRESIGNED_URL -replace '\*','tokenizer_checklist.chk') -OutFile "$TARGET_FOLDER/tokenizer_checklist.chk"
$CPU_ARCH = $env:PROCESSOR_ARCHITECTURE
if ($CPU_ARCH -eq "arm64") {
    cd $TARGET_FOLDER
    Get-FileHash -Algorithm MD5 -Path tokenizer_checklist.chk
}
else {
    cd $TARGET_FOLDER
    Get-FileHash -Algorithm MD5 -Path tokenizer_checklist.chk | Select-Object -ExpandProperty Hash | Out-Null
}

foreach ($m in $MODEL_SIZE -split ',') {
    switch ($m) {
        "7B" {
            $SHARD = 0
            $MODEL_PATH = "llama-2-7b"
        }
        "7B-chat" {
            $SHARD = 0
            $MODEL_PATH = "llama-2-7b-chat"
        }
        "13B" {
            $SHARD = 1
            $MODEL_PATH = "llama-2-13b"
        }
        "13B-chat" {
            $SHARD = 1
            $MODEL_PATH = "llama-2-13b-chat"
        }
        "70B" {
            $SHARD = 7
            $MODEL_PATH = "llama-2-70b"
        }
        "70B-chat" {
            $SHARD = 7
            $MODEL_PATH = "llama-2-70b-chat"
        }
    }

    Write-Host "Downloading $MODEL_PATH"
    $MODEL_FOLDER = Join-Path -Path $TARGET_FOLDER -ChildPath $MODEL_PATH
    New-Item -ItemType Directory -Force -Path $MODEL_FOLDER | Out-Null

    0..$SHARD | ForEach-Object {
        Invoke-WebRequest -Uri ($PRESIGNED_URL -replace '\*',"$MODEL_PATH/consolidated.$_.pth") -OutFile "$MODEL_FOLDER/consolidated.$_.pth"
    }

    Invoke-WebRequest -Uri ($PRESIGNED_URL -replace '\*',"$MODEL_PATH/params.json") -OutFile "$MODEL_FOLDER/params.json"
    Invoke-WebRequest -Uri ($PRESIGNED_URL -replace '\*',"$MODEL_PATH/checklist.chk") -OutFile "$MODEL_FOLDER/checklist.chk"
    Write-Host "Checking checksums"
    if ($CPU_ARCH -eq "arm64") {
        cd $MODEL_FOLDER
        Get-FileHash -Algorithm MD5 -Path checklist.chk
    }
    else {
        cd $MODEL_FOLDER
        Get-FileHash -Algorithm MD5 -Path checklist.chk | Select-Object -ExpandProperty Hash | Out-Null
    }
}
