<#---------------------------------------------------------------------------------------------
.説明
Azureテナント内のプライベートDNSゾーンの仮想ネットワークリンク情報をcsvファイルへ出力します。

.csvフォーマット
<プライベートDNSゾーン名>, <リソースグループ>, <仮想ネットワークリンク名>, <仮想ネットワーク名>
　仮想ネットワークリンク情報がない場合、外套の項目に"-"を出力します。

.ファイル名
指定のファイルパス\getvnetlink.csv
---------------------------------------------------------------------------------------------#>
#　Azureサブスクリプションにサインイン
Connect-AzAccount -usedeviceauthentication -SubscriptionId "<サブスクリプションid>"

#　結果を保存するCSVファイルパスを指定
$outputFilePath = ".\getvnetlink.csv"

#　CSVファイルのヘッダーを設定
$headers = "PrivateDNSZoneName", "ResourceGroupName", "VnetLinkName", "VnetName"

# 結果を格納する配列を初期化
$results = @()

# テナント内のすべてのプライベートDNSゾーンを取得
$privateDnsZones = Get-AzPrivateDnsZone -ResourceGroupName "<プライベートDNSゾーンがあるリソースグループ名>"

foreach ($zone in $privateDnsZones) {
  ## プライベートDNSゾーンにリンクされている仮想ネットワークリンク情報を取得
  $vnetLinks = Get-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $zone.ResourceGroupName -ZoneName $zone.Name

  # CSVファイルに情報をエクスポート
  if ($vnetLinks -ne $null and $vnetLinks.Count -gt 0) {
    foreach ($link in $vnetLinks) {
      $rowData = [PSCustomObject)@{
        "PrivateDNSZoneName" = $zone.Name
        "ResourceGroupName" = $zone.ResourceGroupName
        "VnetLinkName" = $link.Name
        "VnetName" = $link.VirtualNetworkId.Split('/')[-1]
      }
      # 結果を配列に追加
      $results += $rowData
    }
  }
  else {
    # プライベートDNSゾーンにリンクがない場合"-"を出力
    $rowData = [PSCustomObject]@{
      "PrivateDNSZoneName" = $zone.Name
      "ResourceGroupName" = $zone.ResourceGroupName
      "VnetLinkName" = "-"
      "VnetName" = "-"
    }
    # 結果を配列に追加
    $results += $rowData
  }
}

# 結果をCSVファイルに出力
$results | Export-Csv -Path $outputFilePath -NoTypeInformation -Encoding UTF8

# CSVファイルの出力が終了した際にメッセージを表示
if (Test-Path $outputFilePath) {
  Write-Host "CSVファイルに結果を出力しました"
}
else {
  Write-Host "CSVファイルへの結果の出力が失敗しました"
}

# 終了
Disconnect-AzAccount


