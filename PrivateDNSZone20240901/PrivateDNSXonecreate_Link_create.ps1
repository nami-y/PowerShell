<#
.DESCRIPTION
・CSVファイルに記載の仮想ネットワークを参照し、指定したプライベートDNSゾーンを リンクさせます。
・一部のプライベートDNSゾーンの処理を除外することができます。
・すでにリンク済みであれば、処理をスキップします。

事前準備
・.CSVファイルを作成する 仮想ネットワークのリソースIDは、各Vnetの管理画面の「JSON View」からコピーできます。
  VnetResourceID
  <VirtualNetworkResourceId1>
  <VirtualNetworkResourceId2>
  ...

----------------------------------------------------------------------------------------------#> 
#プライベートDNSゾーンがあるサブスクリプションを指定
$PrivateDNSZoneSubscriptionId = "<プライベートDNSゾーンがあるサブスクリプションId>"

# Azure サブスクリプションにサインイン
Connect-AzAccount -usedeviceauthentication -SubscriptionId $PrivateDNSZoneSubscriptionId

<# CSVファイルから仮想ネットワーク名を取得し、$vnetListに格納 #>
$filePath = "Vnet.csv" # CSVファイルのパスを変更
$vnetList = Import-Csv -Path $filePath

# 除外するプライベートDNSゾーンを指定
$excludedZones = @(
  "dev.ch.jp.com",
  "除外するブライベートDNSゾーン名B",
  "除外するプライベートDNSゾーン名C"
)

# プライベートDNSゾーンがあるサブスクリプションをアクティブにする
Set-AzContext -SubscriptionId $PrivateDNSZoneSubscriptionId

# プライベートDNSゾーンを取得 
$privateDnsZones = Get-AzPrivateDnsZone -ResourceGroupName "プライベートDNSゾーンがあるリソースグループ名"

foreach ($zone in $privateDnsZones) {
  # 除外リストに含まれている場合、次のゾーンへスキップ
  if ($zone.Name -in $excludedZones) {
    Write-Host "プライベートDNSゾーン '$($zone.Name)' は除外されました。"
    continue
  }
  Write-Host "処理中のプライベートDNSゾーン: $($zone.Name)"

  # プライベートDNSゾーンがあるサブスクリプションをアクティブにする
  Set-AzContext -SubscriptionId $PrivateDNSZoneSubscriptionId

  #各プライベートDNSゾーンにリンク済みの仮想ネットワークを取得
  $linkedNetworks = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $zone.
  Name -ResourceGroupName $zone.ResourceGroupName | ForEach-Object {
    $vnetId = $_.VirtualNetworkId
    $vnetName = (Get-AzResource -ResourceId $vnetId).Name
    $vnetName
  }

  Write-Host "リンク済みの仮想ネットワーク: $linkedNetworks"

  # CSVファイルに記載の仮想ネットワークから情報を抽出
  foreach ($vnet in $vnetList) {
    $VirtualNetworkId = $vnet.VnetResourceId
    $subscriptionId= ($VirtualNetworkId -split "/")[2]
    $resourceGroupName = ($VirtualNetworkId -split "/")[4]
    $vnetName = ($VirtualNetworkId -split "/")[8]

    Write-Host "処理中の仮想ネットワーク: $vnetName in Resource Group: $resourceGroupName in Subscription: $subscriptionId"

    # 仮想ネットワークのサブスクリプションを設定
    Set-AzContext -SubscriptionId $subscriptionId

    # リソースグループの存在確認
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if ($resourceGroup -eq $null) {
      Write-Host "リソースグループ '$resourceGroupName' がサブスクリプション '$subscriptionId' に見つかりません。"
      continue
    }

    # 各仮想ネットワークのリソースIDを取得
    $vnetResource = Get-AzResource -ResourceGroupName
    $resourceGroupName -ResourceType "Microsoft.Network/virtualNetworks" -ResourceName $vnetName

    if ($vnetResource -eq $null) {
      Write-Host "仮想ネットワークリソースが見つかりません: $vnetName in Resource Group: $resourceGroupName"
      continue
    }

    Write-Host "仮想ネットワークリソースID: $($vnetResource.ResourceId)"

    # プライベートDNSゾーンがあるサブスクリプションをアクティブにする
    Set-AzContext -SubscriptionId $PrivateDNSZoneSubscriptionId

    #リンクされていない仮想ネットワークがある場合は仮想ネットワークリンクを作成
    if ($vnetResource.Name -notin $linkedNetworks) {
      try {
        #仮想ネットワークリンクを作成
        New-AzPrivateDnsVirtualNetworkLink -ZoneName $zone.Name -ResourceGroupName $zone.ResourceGroupName -Name "$($vnetResource.Name)-link" -VirtualNetworkId $vnetResource.ResourceId
        Write-Host "仮想ネットワーク '$($vnetResource.Name)' がプライベートDNSゾーン '$($zone.Name)' にリンクされました。"
      } catch {
        Write-Host "仮想ネットワークリンクの作成に失敗しました: $_"
      }
    } else {
        Write-Host "仮想ネットワーク '$($vnetResource. Name)' は既にリンクされています。"
    }
  }
}

Write-Host "すべてのプライベートDNSゾーンへ仮想ネットワークをリンクしました。"

# 終了
Disconnect-AzAccount






