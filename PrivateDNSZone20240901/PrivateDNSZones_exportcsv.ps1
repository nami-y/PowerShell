<#----------------------------------------------------------------------------------------
.説明
Azureテナント内のプライベートDNSゾーンの仮想ネットワークリンク情報をcsvファイルへ出力します。
※レコードの内容もすべて出力します。

.出力ファイル名：PrivateDNSZones.csv

.スクリプト実行前に下記コマンドにてAzureにログインが必要
Connect-AzAccount -UserDeviceLogin
------------------------------------------------------------------------------------------#>
# CSV出力用のデータを保持するための配列
$output = @()

# すべてのサブスクリプションを取得
$subscriptions = Get-AzSubscription

foreach ($subscription in $subscriptions) {
  Set-AzContext -SubscriptionId $subscription.Id

  # プライベートDNSゾーンを取得
  $dnsZones = Get-AzPrivateDnsZone

  foreach ($zone in $dnsZones) {
    # リソースグループ名を取得
    $resourceGroupName = $zone. ResourceGroupName

    # VNetリンクを取得
    $vnetLinks = Get-AzPrivateDnsVirtualNetworkLink -ResourceGroupName
    $resourceGroupName -ZoneName $zone.Name
    $linkedVnetsCount = $vnetLinks.Count

    # VNet名を取得
    $linkedVnets = @()
    foreach ($link in $vnetLinks) {
      $vnetId= $link.VirtualNetworkId
      $vnetName = ($vnetId -split '/')[8] # VNet名はIDの9番目の部分
      $linkedVnets += $vnetName
    }
    $linkedVnetsString = $linkedVnets -join ','

    # レコードセットを取得
    $recordSets = Get-AzPrivateDnsRecordSet -ResourceGroupName $resourceGroupName -ZoneName $zone.Name
    $recordSetCount = $recordSets.Count

    foreach ($recordSet in $recordSets) {
      # レコードセットの値を取得
      $recordSetValue = $recordSet.Records -join ', '

      # 出力用のカスタムオブジェクトを作成
      $outputObj = [PSCustomObject]@{
        PrivateDNSZoneName = $zone.Name
        SubscriptionName   = $subscription.Name
        ResourceGroupName  = $resourceGroupName
        VnetLinkCount      = $linkedVnetsCount
        LinkedVnets        = $linkedVnetsString
        RecordsetCount     = $recordSetCount
        RecordSetName      = $recordSet.Name
        RecordSetType      = $recordSet.RecordType
        RecordSetTTL       = $recordSet.Ttl
        RecordSetValue     = $recordSetValue
      }
      $output += $outputObj
    }
  }
}

# CSVファイルに出力
$output | Export-Csv -Path "PrivateDNSZones.csv" -NoTypeInformation -Encoding UTF8

Write-Host "CSVファイルが作成されました: PrivateDNSZones.csv"


