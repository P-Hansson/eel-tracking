# This script creates csv file of the box boundary coordinates
# Requires a frame from each video as jpgs

library(geomorph)

#### Place the coordinates and create a tps file ####
# a tps file is usually used for morphometrics but can also be used for this purpose

# Set the working directory to the place you have your images (according to my file diagram, 
# this would be the "create_boundaries/images" file)
# this is also where the tps file will go
setwd("__________/create_boundaries/images")

filelist <- list.files(pattern = "*.jpg")
# Create an empty array specifying the number of landmarks (boundary markers)
# in this case it is set to 16, as there are four boxes each with four corner boundaries
boundaries <- array(0,c(nlandmarks=16, 2, length(filelist)))
dimnames(boundaries)[[3]] <- as.list(filelist)
output_file <- writeland.tps(boundaries, "Box_boundaries_eel.tps")

digitize2d(filelist, nlandmarks = 16, scale = NULL, tpsfile = "Box_boundaries_eel.tps", verbose = TRUE)


#### Create function to move the files once they are done ####
move_images <- function(x) {
  file.rename(from = file.path("./", x), 
              to = file.path("../done", x))
}


#### Convert tps file to csv file ####
Coords_boxes <- data.frame(readland.tps("Box_boundaries_eel.tps", specID = "ID"))

Coords_boxes <- Coords_boxes[,colSums(is.na(Coords_boxes)) == 0]

# Prepare empty vectors for the new items that will be created
video <- vector()
video_name <- vector()
new_col_x <- vector()
new_col_y <- vector()

for (i in 1:ncol(Coords_boxes)) {
  if (grepl("X1", colnames(Coords_boxes[i])) == TRUE) {
    new_col_x <- as.numeric(c(new_col_x, Coords_boxes[,i]))
    video[1:16] <- unlist(strsplit(colnames(Coords_boxes[i]), split = ".", fixed = TRUE))[2]
    video_name <- c(video_name, video)
  }
  if (grepl("X2", colnames(Coords_boxes[i])) == TRUE) {
    new_col_y <- as.numeric(c(new_col_y, Coords_boxes[,i]))
  }
  if (i == tail(ncol(Coords_boxes), n = 1)) {
    new_dataframe <- data.frame(video_name, new_col_x, new_col_y)
    video_name <- vector()
    new_col_x <- vector()
    new_col_y <- vector()
  }
}

# Making sure the boundaries are correctly set
for (vid in unique(new_dataframe$video_name)) {
  temp_bound_df <- new_dataframe[new_dataframe$video_name == vid,]
  temp_bound_df <- subset(temp_bound_df, select = -video_name)
  temp_bound_df$box_nr <- c(1,1,1,1,2,2,2,2,4,4,4,4,3,3,3,3)
  temp_bound_df$positioning <- c(1,2,3,4)
  
  plot(temp_bound_df$new_col_x, temp_bound_df$new_col_y, main = vid, 
       ylab = "", xlab = "")
  
  for (pos in which(temp_bound_df$positioning == 1)) {
    temp_bound_df[nrow(temp_bound_df) + 1,] <- temp_bound_df[pos,]
  }
  
  for (box_id in unique(temp_bound_df$box_nr)) {
    lines(temp_bound_df$new_col_x[temp_bound_df$box_nr == box_id], 
          temp_bound_df$new_col_y[temp_bound_df$box_nr == box_id])
  }
}

# Save the file making sure that any previous file with that name is not overwritten
if (file.exists("../Box_boundaries.csv") == FALSE) {
  write.csv(new_dataframe, file = "../Box_boundaries.csv", row.names = FALSE)
} else {
  write.table(new_dataframe, file = "../Box_boundaries.csv", sep = ",",
              append = TRUE, row.names = FALSE, col.names = FALSE)
}
