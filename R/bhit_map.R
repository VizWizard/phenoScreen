bhit_map <- function(data, well,
                     plate = 96,
                     threshold = 2,
                     title = "",
                     palette = "Spectral"){
    
    require(ggplot2)
    require(dplyr)
    require(RColorBrewer)
    
    # need to transform columns of wellID and data into
    # matrix corresponding to well positions:
    platemap <- as.data.frame(well)
    names(platemap)[1] <- "well"
    
    platemap <- mutate(
        platemap,
        row = as.numeric(match(toupper(substr(well,1,1)),LETTERS)),
        column = as.numeric(substr(well,2,5))
    )
    
    # ensure data is ordered properly before passing to matrix()
    platemap <- platemap[order(platemap$row, platemap$column), ]
    
    
    if (length(well) > plate){
        warning("Invalid plate selection. The data given has more rows then number of wells. \nAre you sure argument 'plate' is correct for the number of wells in your data? \nnote: Default is a 96-well plate.",
                call. = FALSE)
    }
    if (plate > 2 * length(well)){
        warning("Invalid plate selection. The data given has more rows then number of wells. \nAre you sure argument 'plate' is correct for the number of wells in your data? \nnote: Default is a 96-well plate.",
                call. = FALSE)
    }
    if (plate == 96){
        # transform into 12*8 matrix (96-well plate)
        # fills matrix in a row-wise fashion i.e, A01, A02 ...
        mat_plate_map <- matrix(data,
                                nrow = 8,
                                ncol = 12,
                                byrow = TRUE)
    } else if (plate == 384){
        # transform into 24*16 matrix (384-well plate)
        # fills matrix in a row-wise fashion, i.e A01, A02 ...
        mat_plate_map <- matrix(data,
                                nrow = 16,
                                ncol = 24,
                                byrow = TRUE)
    } else{
        stop("Not a plate format. \nArgument 'plate' should be 96 or 384.",
             call. = FALSE)
    }
    
    # median polish of the data
    data_pol <- medpolish(mat_plate_map,
                          na.rm = TRUE)
    
    # transpose of residual matrix (as counts in column-wise fashion)
    # now well numbers correspond i.e t_out[12] = A12, t_out[13] = B01
    t_out <- t(data_pol$residuals)
    
    # 1:96 elements of residuals corresponding to 1:96 of num_to_well
    # produce dataframe of two columns
    df <- NULL
    
    for (num in 1:length(t_out)){
        df$residual[num] <- t_out[num]
        df$well[num] <- num_to_well(num, plate = plate)
    }
    
    df <- as.data.frame(
        cbind("well" = df$well,
              "residual" = df$residual))
    # change residuals from factor to numeric
    df$residual <- as.numeric(as.character(df$residual))
    
    
    # transform well labels into row-column values for a 96-well plate
    platemap <- as.data.frame(df$well)
    names(platemap)[1] <- "well"
    platemap <- mutate(platemap,
                       Row = as.numeric(match(toupper(substr(well, 1, 1)), LETTERS)),
                       Column = as.numeric(substr(well, 2, 5)))
    values <- as.data.frame(data)
    scaled_data <- scale(df$residual)
    platemap <- cbind(platemap, scaled_data[,1])
    names(platemap)[4] <- "scaled_data"
    platemap$hit <- NA
    
    # calculate whether values are beyond the threshold; defined as hit or null
    for (row in 1:nrow(platemap)){
        if (scaled_data[row] > threshold){platemap$hit[row] <- "hit"
        } else  if (scaled_data[row] < (-1 * threshold)){platemap$hit[row] <- "neg_hit"
        } else {platemap$hit[row] <- "null"}
    }
    
    # RColorBrewerPallette
    my_cols <- brewer.pal(3, palette)
    my_colours <- c(hit = my_cols[1], neg_hit = my_cols[3], null = my_cols[2])
    
    # produce a 96-well plate map layout in ggplot
    plt_96 <- ggplot(data = platemap, aes(x = Column, y = Row)) +
        geom_point(data = expand.grid(seq(1, 12), seq(1, 8)), aes(x = Var1, y = Var2),
                   color = "grey90", fill = "white", shape = 21, size = 6) +
        geom_point(aes(fill = hit), colour = "gray20", shape = 21, size = 10) +
        coord_fixed(ratio = (13 / 12) / (9 / 8), xlim = c(0.5, 12.5), ylim = c(0.5, 8.5)) +
        scale_y_reverse(breaks = seq(1, 8), labels = LETTERS[1:8]) +
        scale_x_continuous(breaks = seq(1, 12)) +
        ggtitle(title) + 
        scale_fill_manual("hit", values = my_colours) + 
        theme_bw()
    
    # produce a 384-well plate map layout in ggplot
    plt_384 <- ggplot(data = platemap, aes(x = Column, y = Row)) +
        geom_point(data = expand.grid(seq(1, 24), seq(1, 16)), aes(x = Var1, y = Var2),
                   color = "grey90", fill = "white", shape = 22, size = 3) +
        geom_point(aes(fill = hit), colour = "gray20", shape = 22, size = 5) +
        coord_fixed(ratio = (24.5 / 24) / (16.5 / 16), xlim = c(0.5, 24.5), ylim = c(0.5, 16.5)) +
        scale_y_reverse(breaks = seq(1, 16), labels = LETTERS[1:16]) +
        scale_x_continuous(breaks = seq(1, 24)) +
        ggtitle(title) +
        scale_fill_manual("hit", values = my_colours) + 
        theme_bw()
    
    if (length(well) > plate) {
        stop("Invalid plate selection. The data given has more rows than the number of wells. \nAre you sure argument 'plate' is correct for the number of wells in your data? \nnote: Default is set to a 96-well plate.")
    }
    if (plate == 96) {return(plt_96)}
    if (plate == 384) {return(plt_384)
    } else stop("Not a valid plate format. Either 96 or 384.", call. = FALSE)
    
}