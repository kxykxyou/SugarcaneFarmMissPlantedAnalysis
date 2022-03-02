# SugarcaneFarmMissPlantedAnalysis
Analyzing miss-planted point of sugarcane farm via aerial image, which is a cooperation project with GEOSAT.

## 專案流程

### 步驟
NDVI在偵測植被上的應用：利用紅光與遠紅外光的比例，作為判斷地表空拍圖中綠色的濃度；一般而言地表上綠色的面積會被視為植被面積
以下使用的NDVI圖檔已經轉為灰階；數值越大、越白，表示植被濃度越高；而黑色的區域就為甘蔗田中的走道抑或是缺株處（miss-planted point）  
<img src = 'https://github.com/kxykxyou/SugarcaneFarmMissPlantedAnalysis/blob/main/Illustrations/Illustrations.001.png' width = '500'></img>
<img src = 'https://github.com/kxykxyou/SugarcaneFarmMissPlantedAnalysis/blob/main/Illustrations/Illustrations.002.png' width = '500'></img>

詳細分析策略/步驟如下圖  
<img src = 'https://github.com/kxykxyou/SugarcaneFarmMissPlantedAnalysis/blob/main/Illustrations/Illustrations.003.png' width = '700'></img>

首先要先將圖片旋轉，這與待會使用y軸判斷甘蔗的種植行有關；抑或是可以使用回歸方式計算種植行  
<img src = 'https://github.com/kxykxyou/SugarcaneFarmMissPlantedAnalysis/blob/main/Illustrations/Illustrations.004.png' width = '500'></img>

切小圖，找到有缺株處方便進行測試  
<img src = 'https://github.com/kxykxyou/SugarcaneFarmMissPlantedAnalysis/blob/main/Illustrations/Illustrations.005.png' width = '500'></img>

用MacOS內建的Preview app找出在這個尺度下的健康植株pixel大小（本例中約15x15 pixels）  
<img src = 'https://github.com/kxykxyou/SugarcaneFarmMissPlantedAnalysis/blob/main/Illustrations/Illustrations.006.png' width = '500'></img>

使用kmeans，依照亮度分為5群，且filter出最亮的那一群  
<img src = 'https://github.com/kxykxyou/SugarcaneFarmMissPlantedAnalysis/blob/main/Illustrations/Illustrations.007.png' width = '500'></img>

接著使用DBSCAN，計算每群的群心
理想上應該是一株甘蔗會形成一個群，但生長比較良好的甘蔗植株他的面積就會比較大，連帶連結周圍的植株，形成一個大群
但大群的群心應該還是會落在種植線（行）不遠處，因此不妨礙後續的分析  
<img src = 'https://github.com/kxykxyou/SugarcaneFarmMissPlantedAnalysis/blob/main/Illustrations/Illustrations.008.png' width = '500'></img>

取出每個群心的y座標，以hierarchical clust的方式，將y值相近的群心clust再一起後計算平均（門檻為20 pixels），得到種植行的座標，或稱種植線（planting line）  
<img src = 'https://github.com/kxykxyou/SugarcaneFarmMissPlantedAnalysis/blob/main/Illustrations/Illustrations.009.png' width = '500'></img>

用sliding window的方式，以總和加起來等於植株大小的邊長（15 pixel in case）去scan每一個種植行，計算同個x座標下所有pixels的色彩平均，並輸出為單一向量
該向量可以表示在某種植行中，沿著x方向去看植株的稀疏程度  
<img src = 'https://github.com/kxykxyou/SugarcaneFarmMissPlantedAnalysis/blob/main/Illustrations/Illustrations.010.png' width = '500'></img>

針對上述向量，選擇色彩濃度<35000（尚未normalize）的數值，再進行一次hierarchical clust（門檻為20 pixels，表示每個群最近距離>20），藉此分群出每個不同的缺株點
此外，依照同一群中的色彩濃度<35000的pixel數量分級，並以紅綠燈號的方式表示缺株程度
<img src = 'https://github.com/kxykxyou/SugarcaneFarmMissPlantedAnalysis/blob/main/Illustrations/Illustrations.011.png' width = '500'></img>

最後再將缺株點與嚴重程度對應回原本的x, y座標上
# 

最後就是比較選擇不同植株大小、kmeans分群數、色彩門檻值時，對最後視覺化的影響
<img src = 'https://github.com/kxykxyou/SugarcaneFarmMissPlantedAnalysis/blob/main/Illustrations/Illustrations.012.png' width = '700'></img>
<img src = 'https://github.com/kxykxyou/SugarcaneFarmMissPlantedAnalysis/blob/main/Illustrations/Illustrations.013.png' width = '700'></img>
<img src = 'https://github.com/kxykxyou/SugarcaneFarmMissPlantedAnalysis/blob/main/Illustrations/Illustrations.014.png' width = '700'></img>
