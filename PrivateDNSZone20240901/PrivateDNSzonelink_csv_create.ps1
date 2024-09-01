<#
.DESCRIPTION
・指定したリソースグループ内のプライベートDNSゾーンを抽出し、投入用CSVとして出力する。
・プライベートDNSゾーン"dev.ch.jp.com"を除外する
---------------------------------------------------------------------------#>
# Azureサブスクリプションにサインイン
Connect-AzAccount -usedeviceauthentication -SubscriptionId "<プライベートDNSゾーンがあるサブスクリプションのIDを入力>"

# プライベートDNSゾーンがあるリソースグループ名を入力
$ResourceGroupName = "rg-privatednszone"
# (変更必要)　リンクする仮想ネットワークIdを入力
$VirtualNetworkId = "<仮想ネットワークIDを入力>"
# 除外したいプライベートDNS名を入力
$ExcludedZoneNames = @("dev.ch.jp.com")

# VirtualNetworkIdからVnet名とサブスクリプションIDを抽出（Vnet名はURLの最後の部分）
$VNetName = ($VirtualNetworkId -split "/")[8]
$SubscriptionId = ($VirtualNetworkId -split "/")[2]

# プライベートDNSゾーンの情報を取得
$privateDnsZones = Get-AzPrivateDnsZone -ResourceGroupName $ResourceGroupName

# csvのヘッダーを設定
$csvContent = "ResourceGroupName,PrivateDNSZoneName,PrivateLinkName,VirtualNetworkId`n"

# プライベートDNSゾーンごとに情報を抽出してCSVに追加
foreach ($zone in $privateDnsZones) {
  #除外するプライベートDNSゾーン名をスキップ
  if ($ExcludedZoneNames -contains $zone.Name) {
    continue
  }
  
  $PrivateDNSZoneName = $zone.Name
  $PrivateLinkName = "$VNetName-link"
  $csvContent += "$ResourceGroupName,$PrivateDNSZoneName,$PrivateLinkName,$VirtualNetworkId,$SubscriptionId`n"
}

#csvファイルに保存
$csvPath = "PrivateDNSzonelinkcreate.csv"
$csvContent | out-File -FilePath $csvPath -Encoding UTF8

# 終了
Disconnect-AzAccount

Write-Host "CSVファイルが作成されました: $csvPath"


