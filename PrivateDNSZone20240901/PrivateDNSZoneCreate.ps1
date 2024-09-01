<#
.DESCRIPTION
・PrivateDNSzonelink_csv_create.ps1を実行して出力される"PrivateDNSzonelinkcreate.csv"から
プライベートDNSゾーンの情報を取得し、仮想ネットワークにリンクする。
---------------------------------------------------------------------------#>
# プライベートDNSゾーンのサブスクリプションIDを規定
$PrivateDNSZoneSubscriptionId = "<プライベートDNSゾーンのサブスクリプションIDを入力>"

# Azureサブスクリプションにサインイン
Connect-AzAccount -usedeviceauthentication -SubscriptionId $PrivateDNSZoneSubscriptionId

# CSVファイルのパスを指定
$csvPath = ".\PrivateDNSzonelinkcreate.csv"

# CSVファイルを読み込み
$csvData = Import-Csv -Path $csvPath -Encoding utf8

# 各行に対して仮想ネットワークリンクを作成
foreach ($row in $csvData) {
  $ResourceGroupname = $row.ResourceGroupName
  $PrivateDNSZoneName = $row.PrivateDNSZoneName
  $PrivateLinkName = $row.PrivateLinkName
  $VirtualNetworkId = $row.VirtualNetworkId

  Write-Host "処理中の行： $PrivateDNSZoneName"

  #仮想ネットワークリンクを作成
  try {
    New-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $ResourceGroupName `
      -ZoneName $PrivateDNSZoneName `
      -Name $PrivateLinkName `
      -VirtualNetworkId $VirtualNetworkId `
      -EnableRegistration:$false -ErrorAction Stop
    Write-Host "Success"
  }
  catch {
    Write-Host "仮想ネットワークリンクの作成中にエラーが発生しました： $PrivateLinkName"
    Write-Host "エラーメッセージ： $_.Exception.Message"
  }
}

# 終了
Disconnect-AzAccount


