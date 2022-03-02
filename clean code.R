# 做kmeans
do_kmeans <- function(img, n){
  require(magrittr)
  require(raster)
  kmeans_result <- img %>% getValues() %>% kmeans(., n)
  kmeans_brightest <- data.frame(coordinates(img))[which(kmeans_result$cluster == which(kmeans_result$centers == max(kmeans_result$centers))),]
  return(kmeans_brightest)
}

# 把kmeans的結果做dbscan
do_dbscan <- function(kmeans_brightest, n){
  require(dbscan)
  db <- dbscan(kmeans_brightest, eps = 1.2, minPts = 5)
  return(db)
}

# 找出DBSCAN結果中每一群的中心點且取中心點的y值做hclust，切在15的位置做分群，也就每一群之間差距要大於15個單位
# 分完群之後取平均，相當於把理想種植線找出來
find_planting_line <- function(kmeans_brightest, db, rowdiff){
  center_x <- tapply(kmeans_brightest$x, db$cluster, mean)[-1] %>% as.vector()
  center_y <- tapply(kmeans_brightest$y, db$cluster, mean)[-1] %>% as.vector()
  cluster <- hclust(dist(center_y)) %>% cutree(., h = rowdiff)
  center <- data.frame(center_x, center_y, cluster)
  return(center)
}

# 對缺株處的index做hclust抓出缺株核心index並分級
# 輸出分級後的index
extract_lack <- function(img, kmeans_brightest, db, center, plant_row, plantsize, dens){
  require(magrittr)
  require(raster)
  require(dbscan)
  green <- matrix(nc = 2) %>% na.omit()
  yellow <- matrix(nc = 2) %>% na.omit()
  red <- matrix(nc = 2) %>% na.omit()
  
  values(img) <- values(img)
  img[img==0] <- NA
  for(line in 1:max(center$cluster)){ # 閱覽每一行
    # 把每一row的最左邊到最右邊切出來，extent = (min&max  , y = 理想種植線 +- plant_width/2)
    if(length(center$cluster[which((center$cluster == line))]) > 1){ # 確認每行至少超過1個植株
      # 裁切每行
      # ext <- extent(round(min(center$center_x[which(center$cluster==line)])), round(max(center$center_x[which(center$cluster==line)])), round(plant_row[line]-7.5), round(plant_row[line]+7.5))
      ext <- extent(0, dim(img)[2], round(plant_row[line]-plantsize/2), round(plant_row[line]+plantsize/2))
      window_weight <- matrix(1, nr = plantsize, nc = 1)
      # run sliding window & 抓出空缺處的中心點
      img_focal <- focal(crop(img, ext), w = window_weight, fun = mean, na.rm = F)
      focal_pts <- which(getValues(img_focal < 30000))
      if(length(focal_pts)>5){
        focal_pts_cluster <- cutree(hclust(dist(which(getValues(img_focal < 30000)))), h = 30)
        for(cluster in 1:length(table(focal_pts_cluster))){
          if(table(focal_pts_cluster)[cluster] > 5 & table(focal_pts_cluster)[cluster] <= 10){
            green <- rbind(green, coordinates(img_focal)[round(tapply(focal_pts, focal_pts_cluster, median))[cluster], ])
          }else if(table(focal_pts_cluster)[cluster] > 10 & table(focal_pts_cluster)[cluster] <= 15){
            yellow <- rbind(yellow, coordinates(img_focal)[round(tapply(focal_pts, focal_pts_cluster, median))[cluster], ])
          }else if(table(focal_pts_cluster)[cluster] > 15){
            red <- rbind(red, coordinates(img_focal)[round(tapply(focal_pts, focal_pts_cluster, median))[cluster], ])
          }else{next}
        }
      }else{next}
    }else{next}
  }
  return(list(green, yellow, red)) #回傳不同程度缺株的dataframe
}

main <- function(filename = 'sugarcane_NDVI_rotate.tif', filename.out, plantsize = 15, kmeans = 5, dens = 35000){
  require(raster)
  t1 <- Sys.time()
  img <- raster(filename)
  
  kmeans_brightest <- do_kmeans(img, kmeans)
  db <- do_dbscan(kmeans_brightest, kmeans)
  center <- find_planting_line(kmeans_brightest, db, rowdiff = 20)
  plant_row <- tapply(center$center_y, center$cluster, mean)
  l <- extract_lack(img, kmeans_brightest = kmeans_brightest, db = db, center = center, plant_row = plant_row, plantsize = plantsize, dens = dens)
  
  green <- as.data.frame(l[1])
  yellow <- as.data.frame(l[2])
  red <- as.data.frame(l[3])
  img_coordinate <- as.data.frame(coordinates(img))
  
  green_ind <- c()
  yellow_ind <- c()
  red_ind <- c()
  for(i in 1:length(green$x)){
    green_ind <- c(green_ind, which(img_coordinate$x == green$x[i] & img_coordinate$y == green$y[i]))
  }
  
  for(i in 1:length(yellow$x)){
    yellow_ind <- c(yellow_ind, which(img_coordinate$x == yellow$x[i] & img_coordinate$y == yellow$y[i]))
  }
  
  for(i in 1:length(red$x)){
    red_ind <- c(red_ind, which(img_coordinate$x == red$x[i] & img_coordinate$y == red$y[i]))
  }
  
  require(grDevices)
  # 點上缺株處
  tiff(filename = filename.out, width = dim(img)[2], height = dim(img)[1], compression = 'none')
  plot(img, main = 'Sugarcane farm image analysis', cex.main = 3, col = colorRampPalette(c('black', 'white'))(length(unique(values(img)))))
  legend('topright', pch = 16, col = c('green', 'yellow', 'red'), legend = c('Mild', 'Medium', 'Severe'), cex = 5, pt.cex = 5)
  points(coordinates(img)[,1][green_ind], coordinates(img)[,2][green_ind], pch = 16, col = 'green', cex = 2)
  points(coordinates(img)[,1][yellow_ind], coordinates(img)[,2][yellow_ind], pch = 16, col = 'yellow', cex = 2)
  points(coordinates(img)[,1][red_ind], coordinates(img)[,2][red_ind], pch = 16, col = 'red', cex = 2)
  dev.off()
  t2 <- Sys.time()
  print(t2-t1)
}

# 從讀圖到標註、輸出存擋
main(filename.out = 'result.tif')

