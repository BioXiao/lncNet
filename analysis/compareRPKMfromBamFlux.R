lnc.v19.list <<- "/home/wespisea/data/gtf//gencode.v19.long_noncoding_RNAs.geneList"
pc.v19.list <<- "/home/wespisea/data/gtf//gencode.v19.annotation.pc.geneList"





convertTransToTransFull <- function(transFile,geneFile){
  tf <- tempfile()
  system( paste("cat",transFile," | sed 's/[;\"]//g' |awk -F' ' '{print $10,$12,$14}' > ",tf))
  trans.df <- read.csv(file=tf, sep=" ", stringsAsFactors=FALSE,header=FALSE)
  file.remove(tf)
  colnames(trans.df) <- c("gene_id", "transcript_id", "RPKM")
  trans.df$RPKM = as.numeric(trans.df$RPKM)
  exportAsTable(df=trans.df  ,file=geneFile)
}

convertTransToGeneGtfReads <- function(transFile,geneFile){
  tf <- tempfile()
  system( paste("cat",transFile," | sed 's/[;\"]//g' |awk -F' ' '{print $10,$12,$14,$4,$5,$6}' > ",tf))
  trans.df <- read.csv(file=tf, sep=" ", stringsAsFactors=FALSE,header=FALSE)
  file.remove(tf)
  colnames(trans.df) <- c("gene_id", "transcript_id", "RPKM","startPos","stopPos","reads")
  trans.df$RPKM <- NULL
  trans.df$startPos <- NULL
  trans.df$stopPos <- NULL
  exportAsTable(df=trans.df  ,file=geneFile)
}

processCellsMaxTransExprReads <- function(){
  annot.df <- getRpkmFromBamDataForOneCell()
  annot.df <- annot.df[which(annot.df$rnaExtract == "longPolyA"),]
  annot.df <- annot.df[-which(annot.df$cell == "H1-hESC"),]
  genes <- annot.df$rfbGene
  trans <- annot.df$rpkmFromBamFile
  annot.df$rep <- ifelse(annot.df$replicate >2,annot.df$replicate -2,annot.df$replicate )
  annot.df$transFullReads<- gsub(x=annot.df$rfbGene,pattern="genes",replacement="transFullReads")
  transFullReads <- annot.df$transFullReads 
  sapply(seq_along(transFullReads), function(x)convertTransToGeneGtfReads(transFile=trans[x],geneFile=transFullReads[x]))
  df.together <- data.frame()
  for ( cell in unique(annot.df$cell)){
    print(cell)
    a.cell <- annot.df[which(annot.df$cell == cell),]
    a.cell.cyt1 <- read.csv(file=a.cell[which(a.cell$rep == 1 & a.cell$localization == "cytosol"),"transFullReads"],sep="\t",stringsAsFactors=FALSE)
    a.cell.cyt1$loc <- "cytosol"
    a.cell.cyt1$rep <- 1
    a.cell.nuc1 <- read.csv(file=a.cell[which(a.cell$rep == 1 & a.cell$localization == "nucleus"),"transFullReads"],sep="\t",stringsAsFactors=FALSE)
    a.cell.nuc1$loc <- "nucleus"
    a.cell.nuc1$rep <- 1
    a.cell.cyt2 <- read.csv(file=a.cell[which(a.cell$rep == 2 & a.cell$localization == "cytosol"),"transFullReads"],sep="\t",stringsAsFactors=FALSE)
    a.cell.cyt2$loc <- "cytosol"
    a.cell.cyt2$rep <- 2
    a.cell.nuc2 <- read.csv(file=a.cell[which(a.cell$rep == 2 & a.cell$localization == "nucleus"),"transFullReads"],sep="\t",stringsAsFactors=FALSE)
    a.cell.nuc2$loc <- "nucleus"
    a.cell.nuc2$rep <- 2
    
    comb <- rbind(a.cell.cyt1,a.cell.cyt2,a.cell.nuc1,a.cell.nuc2)
    transExpr <- as.data.frame(group_by(comb,gene_id,transcript_id) %.% summarise(sum(reads)))
    colnames(transExpr) <- c("gene_id","transcript_id","Readsum")
    transExpr$Reads_tieBreaker <- transExpr$Readsum + runif(seq_along(transExpr$Readsum))/(10^9)
    gene.df <- as.data.frame(group_by(transExpr, gene_id) %.% filter(Reads_tieBreaker == max(Reads_tieBreaker))) 
    cellTranscripts <- gene.df$transcript_id
    cTrans <- comb[which(comb$transcript_id %in% cellTranscripts),]
    cTrans$cell <- cell                       
    if (i == 1){
      df.together <- cTrans
      
    } else{
      df.together <- rbind(df.together,cTrans)
    }
  }
  exportAsTable(file=getFullPath("data/rpkmFromBam-TopTransCellType-Reads.tab"),df=df.together)
}


doit <- function(){
processCellsMaxTransExpr()
getDataTotalReadsBtwnReps_rpkmFromBamTopTrans()
getDataExprBoth()
}

processCellsMaxTransExpr <- function(){
  annot.df <- getRpkmFromBamDataForOneCell()
  annot.df <- annot.df[which(annot.df$rnaExtract == "longPolyA"),]
  annot.df <- annot.df[-which(annot.df$cell == "H1-hESC"),]
  genes <- annot.df$rfbGene
  trans <- annot.df$rpkmFromBamFile
  annot.df$rep <- ifelse(annot.df$replicate >2,annot.df$replicate -2,annot.df$replicate )
  annot.df$transFullRPKM <- gsub(x=annot.df$rfbGene,pattern="genes",replacement="transFullRPKM")
  transFullRPKM <- annot.df$transFullRPKM 
  sapply(seq_along(transFullRPKM), function(x)convertTransToTransFull(transFile=trans[x],geneFile=transFullRPKM[x]))
  df.together <- data.frame()
  for ( cell in unique(annot.df$cell)){
    print(cell)
    a.cell <- annot.df[which(annot.df$cell == cell),]
    a.cell.cyt1 <- read.csv(file=a.cell[which(a.cell$rep == 1 & a.cell$localization == "cytosol"),"transFullRPKM"],sep="\t",stringsAsFactors=FALSE)
    a.cell.cyt1$loc <- "cytosol"
    a.cell.cyt1$rep <- 1
    a.cell.nuc1 <- read.csv(file=a.cell[which(a.cell$rep == 1 & a.cell$localization == "nucleus"),"transFullRPKM"],sep="\t",stringsAsFactors=FALSE)
    a.cell.nuc1$loc <- "nucleus"
    a.cell.nuc1$rep <- 1
    a.cell.cyt2 <- read.csv(file=a.cell[which(a.cell$rep == 2 & a.cell$localization == "cytosol"),"transFullRPKM"],sep="\t",stringsAsFactors=FALSE)
    a.cell.cyt2$loc <- "cytosol"
    a.cell.cyt2$rep <- 2
    a.cell.nuc2 <- read.csv(file=a.cell[which(a.cell$rep == 2 & a.cell$localization == "nucleus"),"transFullRPKM"],sep="\t",stringsAsFactors=FALSE)
    a.cell.nuc2$loc <- "nucleus"
    a.cell.nuc2$rep <- 2
    
    comb <- rbind(a.cell.cyt1,a.cell.cyt2,a.cell.nuc1,a.cell.nuc2)
    transExpr <- as.data.frame(group_by(comb,gene_id,transcript_id) %.% summarise(sum(RPKM)))
    colnames(transExpr) <- c("gene_id","transcript_id","RPKMsum")
    transExpr$RPKM_tieBreaker <- transExpr$RPKMsum + runif(seq_along(transExpr$RPKMsum))/(10^9)
    gene.df <- as.data.frame(group_by(transExpr, gene_id) %.% filter(RPKM_tieBreaker == max(RPKM_tieBreaker))) 
    cellTranscripts <- gene.df$transcript_id
    cTrans <- comb[which(comb$transcript_id %in% cellTranscripts),]
    cTrans$cell <- cell                       
    if (i == 1){
      df.together <- cTrans
      
    } else{
      df.together <- rbind(df.together,cTrans)
    }
  }
  exportAsTable(file=getFullPath("data/rpkmFromBam-TopTransCellType.tab"),df=df.together)
}

getDataTotalReadsBtwnReps_rpkmFromBamTopTrans <- function(){
  df.together <- read.csv(file=getFullPath("data/rpkmFromBam-TopTransCellType.tab"),sep="\t")
  pc <- readLines(pc.v19.list)
  lnc <- readLines(lnc.v19.list)
  df.together$region <- "other"
  df.together[which(df.together$gene_id %in% lnc),"region"] <- "lnc"
  df.together[which(df.together$gene_id %in% pc),"region"] <- "mRNA"
  df.together$gene_type <- df.together$region
  df.together$rnaExtract = "longPolyA"
  df.together$localization <- df.together$loc
  df.together$replicate <- df.together$rep
  df.together$RPKM <- as.numeric(df.together$RPKM)
  df.together$isSpikeIn <- 0
  df.together[grep(pattern="ERCC",df.together$gene_id),"isSpikeIn"] <- 1
  
  report.df  <- as.data.frame(group_by(df.together,cell,localization,replicate) %.%
                                summarise(length(gene_id),
                                          mean(RPKM),
                                          sum(RPKM),
                                          sum(RPKM > 0)))
  report.df$experiment <- paste(ifelse(report.df$localization == "cytosol", "cyt", "nuc"),report.df$replicate,sep=".")
  colnames(report.df) <- c("cell", "localization", "replicate", "genesFound", "meanRPKM", 
                           "sumRPKM","genesExpressed", "experiment")
  exportAsTable(df=report.df, file = getFullPath("/data/rpkmFromBAMTopTrans-lpa-proc-REPORT.tab"))
  
  df.together <- as.data.frame(group_by(df.together, cell, localization,rnaExtract,replicate) %.% 
                                 mutate(RPKM_80norm = apply80norm(RPKM) * 1000000))
  
  #  group_by(df.together, cell, localization,rnaExtract,replicate) %.% summarise(mean(RPKM_80norm/transTotalRPKM, na.rm=TRUE))
  
  exportAsTable(file=getFullPath("/data/rpkmFromBamTopTransAllCells.tab"), df=df.together)
  df.together$gene_type <- df.together$region
  df.abbrev <- df.together[ c("region","replicate", "gene_id","gene_type", "localization","rnaExtract","cell", "isSpikeIn", "RPKM_80norm","RPKM")]
  
  df.rep.1 <- subset(df.abbrev, replicate == 1)
  df.rep.2 <- subset(df.abbrev, replicate == 2)
  
  df.cyt.rep1 <- subset(df.rep.1, localization == "cytosol")
  df.cyt.rep2 <- subset(df.rep.2, localization == "cytosol")
  idVars <-  c("gene_id","gene_type", "localization","rnaExtract","cell", "isSpikeIn","replicate","region")
  idVarsNorep <- c("variable","gene_id","gene_type", "localization","rnaExtract","cell", "isSpikeIn","region")
  df.cyt.rep1.melt <- melt(df.cyt.rep1, id.vars = idVars)
  df.cyt.rep2.melt <- melt(df.cyt.rep2, id.vars = idVars)
  df.cyt <- merge(df.cyt.rep1.melt, df.cyt.rep2.melt, by = idVarsNorep,suffixes=c(".rep1", ".rep2"))
  df.cyt$expr <- paste(df.cyt$localization,df.cyt$rnaExtract)
  df.cyt$value.rep1 <- ifelse(is.na(as.numeric(df.cyt$value.rep1)), 0, as.numeric(df.cyt$value.rep1))
  df.cyt$value.rep2 <-  ifelse(is.na(as.numeric(df.cyt$value.rep2)), 0, as.numeric(df.cyt$value.rep2))
  
  df.cyt$value.rep1.pseudo <- applyPseudoValByVar2(value= df.cyt$value.rep1, var=df.cyt$variable)
  df.cyt$value.rep2.pseudo <- applyPseudoValByVar2(value = df.cyt$value.rep2 , var=df.cyt$variable)
  
  df.cyt$rep1.frac <- df.cyt$value.rep1/(df.cyt$value.rep1 + df.cyt$value.rep2)
  df.cyt$rep1.frac.pseudo <- df.cyt$value.rep1.pseudo/(df.cyt$value.rep1.pseudo + df.cyt$value.rep2.pseudo)
  
  df.cyt$rep2.frac <- df.cyt$value.rep2/(df.cyt$value.rep1 + df.cyt$value.rep2)
  df.cyt$rep2.frac.pseudo <- df.cyt$value.rep2.pseudo/(df.cyt$value.rep1.pseudo + df.cyt$value.rep2.pseudo)
  
  df.cyt$rep.ratio <- df.cyt$value.rep1/( df.cyt$value.rep2)
  df.cyt$rep.ratio.pseudo <- df.cyt$value.rep1.pseudo/(df.cyt$value.rep2.pseudo)
  
  df.cyt$value.ave <- (df.cyt$value.rep1 + df.cyt$value.rep2)/2
  
  
  df.nuc.rep1 <- subset(df.rep.1, localization == "nucleus")
  df.nuc.rep2 <- subset(df.rep.2, localization == "nucleus")
  
  idVars <-  c("gene_id","gene_type", "localization","rnaExtract","cell", "isSpikeIn","replicate","region")
  idVarsNorep <- c("variable","gene_id","gene_type", "localization","rnaExtract","cell", "isSpikeIn","region")
  df.nuc.rep1.melt <- melt(df.nuc.rep1, id.vars=idVars)
  df.nuc.rep2.melt <- melt(df.nuc.rep2, id.vars = idVars)
  df.nuc <- merge(df.nuc.rep1.melt, df.nuc.rep2.melt, by = idVarsNorep,suffixes=c(".rep1", ".rep2"))
  df.nuc$expr <- paste(df.nuc$localization,df.nuc$rnaExtract)
  df.nuc$value.rep1 <- ifelse(is.na(as.numeric(df.nuc$value.rep1)), 0, as.numeric(df.nuc$value.rep1))
  df.nuc$value.rep2 <-  ifelse(is.na(as.numeric(df.nuc$value.rep2)), 0, as.numeric(df.nuc$value.rep2))
  
  df.nuc$value.rep1.pseudo <- applyPseudoValByVar2(value= df.nuc$value.rep1, var=df.nuc$variable)
  df.nuc$value.rep2.pseudo <- applyPseudoValByVar2(value = df.nuc$value.rep2 , var=df.nuc$variable)
  
  df.nuc$rep1.frac <- df.nuc$value.rep1/(df.nuc$value.rep1 + df.nuc$value.rep2)
  df.nuc$rep1.frac.pseudo <- df.nuc$value.rep1.pseudo/(df.nuc$value.rep1.pseudo + df.nuc$value.rep2.pseudo)
  
  df.nuc$rep2.frac <- df.nuc$value.rep2/(df.nuc$value.rep1 + df.nuc$value.rep2)
  df.nuc$rep2.frac.pseudo <- df.nuc$value.rep2.pseudo/(df.nuc$value.rep1.pseudo + df.nuc$value.rep2.pseudo)
  
  df.nuc$rep.ratio <- df.nuc$value.rep1/( df.nuc$value.rep2)
  df.nuc$rep.ratio.pseudo <- df.nuc$value.rep1.pseudo/(df.nuc$value.rep2.pseudo)
  
  df.nuc$value.ave <- (df.nuc$value.rep1 + df.nuc$value.rep2)/2
  
  
  #df.cytNuc <- rbind(df.cyt,df.nuc)
  #df.cytNuc[which(df.cytNuc$gene_id %in% pc),"region"] <- "mRNA"
  #df.cytNuc[which(df.cytNuc$gene_id %in% lnc),"region"] <- "lncRNA"
  
  df.cytNuc <- merge(df.cyt,df.nuc,by=c("gene_id","cell","variable"),suffixes=c(".cyt",".nuc"))
  
  
  exportAsTable(file=getFullPath("/data/rpkmFromBamCapDataTopTrans-lpa-proc.tab"), df=df.cytNuc)
  
}
getDataTotalReadsBtwnReps_readsFromBamTopTrans <- function(){
  df.together <- read.csv(file=getFullPath("data/rpkmFromBam-TopTransCellType-Reads.tab"),sep="\t")
  pc <- readLines(pc.v19.list)
  lnc <- readLines(lnc.v19.list)
  df.together$region <- "other"
  df.together[which(df.together$gene_id %in% lnc),"region"] <- "lnc"
  df.together[which(df.together$gene_id %in% pc),"region"] <- "mRNA"
  df.together$gene_type <- df.together$region
  df.together$rnaExtract = "longPolyA"
  df.together$localization <- df.together$loc
  df.together$replicate <- df.together$rep
  df.together$reads <- as.numeric(df.together$reads)
  df.together$isSpikeIn <- 0
  df.together[grep(pattern="ERCC",df.together$gene_id),"isSpikeIn"] <- 1
    
  #  group_by(df.together, cell, localization,rnaExtract,replicate) %.% summarise(mean(RPKM_80norm/transTotalRPKM, na.rm=TRUE))
  
  exportAsTable(file=getFullPath("/data/rpkmFromBamTopTransAllCells-READS.tab"), df=df.together)
  df.together$gene_type <- df.together$region
  df.abbrev <- df.together[ c("region","replicate", "gene_id","gene_type", "localization","rnaExtract","cell", "isSpikeIn", "reads")]
  
  df.rep.1 <- subset(df.abbrev, replicate == 1)
  df.rep.2 <- subset(df.abbrev, replicate == 2)
  
  df.cyt.rep1 <- subset(df.rep.1, localization == "cytosol")
  df.cyt.rep2 <- subset(df.rep.2, localization == "cytosol")
  idVars <-  c("gene_id","gene_type", "localization","rnaExtract","cell", "isSpikeIn","replicate","region")
  idVarsNorep <- c("variable","gene_id","gene_type", "localization","rnaExtract","cell", "isSpikeIn","region")
  df.cyt.rep1.melt <- melt(df.cyt.rep1, id.vars = idVars)
  df.cyt.rep2.melt <- melt(df.cyt.rep2, id.vars = idVars)
  df.cyt <- merge(df.cyt.rep1.melt, df.cyt.rep2.melt, by = idVarsNorep,suffixes=c(".rep1", ".rep2"))
  df.cyt$expr <- paste(df.cyt$localization,df.cyt$rnaExtract)
  df.cyt$value.rep1 <- ifelse(is.na(as.numeric(df.cyt$value.rep1)), 0, as.numeric(df.cyt$value.rep1))
  df.cyt$value.rep2 <-  ifelse(is.na(as.numeric(df.cyt$value.rep2)), 0, as.numeric(df.cyt$value.rep2))
  
  df.cyt$value.rep1.pseudo <- applyPseudoValByVar2(value= df.cyt$value.rep1, var=df.cyt$variable)
  df.cyt$value.rep2.pseudo <- applyPseudoValByVar2(value = df.cyt$value.rep2 , var=df.cyt$variable)
  
  df.cyt$rep1.frac <- df.cyt$value.rep1/(df.cyt$value.rep1 + df.cyt$value.rep2)
  df.cyt$rep1.frac.pseudo <- df.cyt$value.rep1.pseudo/(df.cyt$value.rep1.pseudo + df.cyt$value.rep2.pseudo)
  
  df.cyt$rep2.frac <- df.cyt$value.rep2/(df.cyt$value.rep1 + df.cyt$value.rep2)
  df.cyt$rep2.frac.pseudo <- df.cyt$value.rep2.pseudo/(df.cyt$value.rep1.pseudo + df.cyt$value.rep2.pseudo)
  
  df.cyt$rep.ratio <- df.cyt$value.rep1/( df.cyt$value.rep2)
  df.cyt$rep.ratio.pseudo <- df.cyt$value.rep1.pseudo/(df.cyt$value.rep2.pseudo)
  
  df.cyt$value.ave <- (df.cyt$value.rep1 + df.cyt$value.rep2)/2
  
  
  df.nuc.rep1 <- subset(df.rep.1, localization == "nucleus")
  df.nuc.rep2 <- subset(df.rep.2, localization == "nucleus")
  
  idVars <-  c("gene_id","gene_type", "localization","rnaExtract","cell", "isSpikeIn","replicate","region")
  idVarsNorep <- c("variable","gene_id","gene_type", "localization","rnaExtract","cell", "isSpikeIn","region")
  df.nuc.rep1.melt <- melt(df.nuc.rep1, id.vars=idVars)
  df.nuc.rep2.melt <- melt(df.nuc.rep2, id.vars = idVars)
  df.nuc <- merge(df.nuc.rep1.melt, df.nuc.rep2.melt, by = idVarsNorep,suffixes=c(".rep1", ".rep2"))
  df.nuc$expr <- paste(df.nuc$localization,df.nuc$rnaExtract)
  df.nuc$value.rep1 <- ifelse(is.na(as.numeric(df.nuc$value.rep1)), 0, as.numeric(df.nuc$value.rep1))
  df.nuc$value.rep2 <-  ifelse(is.na(as.numeric(df.nuc$value.rep2)), 0, as.numeric(df.nuc$value.rep2))
  
  df.nuc$value.rep1.pseudo <- applyPseudoValByVar2(value= df.nuc$value.rep1, var=df.nuc$variable)
  df.nuc$value.rep2.pseudo <- applyPseudoValByVar2(value = df.nuc$value.rep2 , var=df.nuc$variable)
  
  df.nuc$rep1.frac <- df.nuc$value.rep1/(df.nuc$value.rep1 + df.nuc$value.rep2)
  df.nuc$rep1.frac.pseudo <- df.nuc$value.rep1.pseudo/(df.nuc$value.rep1.pseudo + df.nuc$value.rep2.pseudo)
  
  df.nuc$rep2.frac <- df.nuc$value.rep2/(df.nuc$value.rep1 + df.nuc$value.rep2)
  df.nuc$rep2.frac.pseudo <- df.nuc$value.rep2.pseudo/(df.nuc$value.rep1.pseudo + df.nuc$value.rep2.pseudo)
  
  df.nuc$rep.ratio <- df.nuc$value.rep1/( df.nuc$value.rep2)
  df.nuc$rep.ratio.pseudo <- df.nuc$value.rep1.pseudo/(df.nuc$value.rep2.pseudo)
  
  df.nuc$value.ave <- (df.nuc$value.rep1 + df.nuc$value.rep2)/2
  
  
  #df.cytNuc <- rbind(df.cyt,df.nuc)
  #df.cytNuc[which(df.cytNuc$gene_id %in% pc),"region"] <- "mRNA"
  #df.cytNuc[which(df.cytNuc$gene_id %in% lnc),"region"] <- "lncRNA"
  
  df.cytNuc <- merge(df.cyt,df.nuc,by=c("gene_id","cell","variable"),suffixes=c(".cyt",".nuc"))
  
  
  exportAsTable(file=getFullPath("data/rpkmFromBam-TopTransCellType-Reads-Proc.tab"), df=df.cytNuc)
  
}

plotRatiosTopTrans <- function(){
  
  df.cytNuc <- read.csv(sep="\t",file=getFullPath("/data/rpkmFromBamCapDataTopTrans-lpa-proc.tab"))
  df.cytNuc$cytFracPseudo <- with(df.cytNuc, (value.rep1.pseudo.cyt+value.rep2.pseudo.cyt)/(value.rep1.pseudo.cyt + value.rep2.pseudo.cyt + value.rep1.pseudo.nuc + value.rep2.pseudo.nuc))
  df.cytNuc$cytFrac <- with(df.cytNuc, (value.ave.cyt)/(value.ave.cyt + value.ave.nuc))
  
  df.cytNuc.pos <- df.cytNuc[which(df.cytNuc$value.ave.cyt != 0 & df.cytNuc$value.ave.nuc != 0),]
  
  
  df.lpa.ratio.rpkm <- df.cytNuc.pos[which(df.cytNuc.pos$variable =="RPKM"),]
  df.lpa.ratio.rpkm80 <- df.cytNuc.pos[which(df.cytNuc.pos$variable =="RPKM_80norm"),]
  
  ggplot(df.lpa.ratio.rpkm, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFracPseudo,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("RPKMfromBAM Top Trans\nFraction of Cytosolic RNA-seq expr\nRPKM: cytPseudo/(nucPseudo + cytPseudo)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/rpkmPseudo-cells.png"), height=12,width=5)
  
  ggplot(df.lpa.ratio.rpkm, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFrac,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("RPKMfromBAM Top Trans\nFraction of Cytosolic RNA-seq expr\nRPKM: cyt/(nuc + cyt)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/rpkm-cells.png"), height=12,width=5)
  
  ggplot(df.lpa.ratio.rpkm, aes(x=cytFracPseudo,fill=factor(region.cyt)))+
    geom_bar(position="dodge") + theme_bw() + thisTheme + 
    facet_grid(cell~.)+
    ggtitle("RPKMfromBAM Top Trans\nFraction of Cytosolic RNA-seq expr\nRPKM: cytPseudo/(nucPseudo + cytPseudo)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/rpkmPseudo-bars-cells.png"), height=12,width=5)
  
  ggplot(df.lpa.ratio.rpkm, aes(x=cytFrac,,fill=factor(region.cyt)))+
    geom_bar(position="dodge") + theme_bw() + thisTheme + 
    facet_grid(cell~.)+
    ggtitle("RPKMfromBAM Top Trans\nFraction of Cytosolic RNA-seq expr\nRPKM: cyt/(nuc + cyt)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/rpkm-bars-cells.png"), height=12,width=5)
  
  
  #RPKM80 norm
  ggplot(df.lpa.ratio.rpkm80, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFracPseudo,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("RPKMfromBAM Top Trans\nFraction of Cytosolic RNA-seq expr\nRPKM80: cytPseudo/(nucPseudo + cytPseudo)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/rpkm80Pseudo-cells.png"), height=12,width=5)
  
  ggplot(df.lpa.ratio.rpkm80, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFrac,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("RPKMfromBAM Top Trans\nFraction of Cytosolic RNA-seq expr\nRPKM80: cyt/(nuc + cyt)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/rpkm80-cells.png"), height=12,width=5)
  
  
}




getDataExprBoth <- function(){
  df.flux <- read.csv(file=getFullPath("/data/fluxCapData-lpa-proc.tab"),sep="\t")
  df.flux.cyt <- as.data.frame(group_by(df.flux, cell) %.%
                                filter(rnaExtract =="longPolyA") %.%
                                filter(localization == "cytosol"))
  
  df.flux.nuc <- as.data.frame(group_by(df.flux, cell) %.%
                                filter(rnaExtract =="longPolyA") %.%
                                filter(localization == "nucleus"))
  
  df.flux.ratio <- merge(df.flux.nuc,df.flux.cyt,by=c("gene_id","cell","variable"),suffixes=c(".nuc",".cyt"))
  df.flux.ratio$cytFracPseudo <- with(df.flux.ratio, (value.rep1.pseudo.cyt+value.rep2.pseudo.cyt)/(value.rep1.pseudo.cyt + value.rep2.pseudo.cyt + value.rep1.pseudo.nuc + value.rep2.pseudo.nuc))
  df.flux.ratio$cytFrac <- with(df.flux.ratio, (value.ave.cyt)/(value.ave.cyt + value.ave.nuc))
  
  df.flux.ratio$cytFracPseudo <- with(df.flux.ratio, (value.rep1.pseudo.cyt+value.rep2.pseudo.cyt)/(value.rep1.pseudo.cyt + value.rep2.pseudo.cyt + value.rep1.pseudo.nuc + value.rep2.pseudo.nuc))
  df.flux.ratio$cytFrac <- with(df.flux.ratio, (value.ave.cyt)/(value.ave.cyt + value.ave.nuc))
  df.flux.ratio.pos <- df.flux.ratio[which(df.flux.ratio$value.ave.cyt != 0 & df.flux.ratio$value.ave.nuc != 0),]
  df.flux.ratio.rpkm <- df.flux.ratio.pos[which(df.flux.ratio.pos$variable =="transTotalRPKM"),]
  df.flux.ratio.rpkm$cellGene <- with(df.flux.ratio.rpkm,paste(gene_id,cell))
  
  
  df.cytNuc <- read.csv(sep="\t",file=getFullPath("/data/rpkmFromBamCapDataTopTrans-lpa-proc.tab"))
  df.cytNuc$cytFracPseudo <- with(df.cytNuc, (value.rep1.pseudo.cyt+value.rep2.pseudo.cyt)/(value.rep1.pseudo.cyt + value.rep2.pseudo.cyt + value.rep1.pseudo.nuc + value.rep2.pseudo.nuc))
  df.cytNuc$cytFrac <- with(df.cytNuc, (value.ave.cyt)/(value.ave.cyt + value.ave.nuc))
  df.cytNuc.pos <- df.cytNuc[which(df.cytNuc$value.ave.cyt != 0 & df.cytNuc$value.ave.nuc != 0),]
  df.lpa.ratio.rpkm <- df.cytNuc.pos[which(df.cytNuc.pos$variable =="RPKM"),]
  df.lpa.ratio.rpkm$cellGene <- with(df.lpa.ratio.rpkm,paste(gene_id,cell))
  bam.cells <- unique(df.lpa.ratio.rpkm$cell)
  
  df.flux.ratio.rpkm <- df.flux.ratio.rpkm[which(df.flux.ratio.rpkm$cell %in% unique(df.lpa.ratio.rpkm$cell)),]
  
  df.lpa.ratio.rpkm <- df.lpa.ratio.rpkm[which(df.lpa.ratio.rpkm$cellGene %in%  df.flux.ratio.rpkm$cellGene),]
  
  ggplot(df.lpa.ratio.rpkm, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFracPseudo,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("RPKMfromBAM same trans in cell type\nFraction of Cytosolic RNA-seq expr\nRPKM: cytPseudo/(nucPseudo + cytPseudo)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/rpkmPseudo-fluxOnly-cells.png"), height=12,width=5)
  
  ggplot(df.flux.ratio.rpkm, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFracPseudo,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("Flux\nFraction of Cytosolic RNA-seq expr\nRPKM: cytPseudo/(nucPseudo + cytPseudo)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/rpkmPseudoFlux-cells.png"), height=12,width=5)
  
  
  ggplot(df.lpa.ratio.rpkm, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFrac,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("RPKMfromBAM\nFraction of Cytosolic RNA-seq expr\nRPKM: cyt/(nuc + cyt)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/rpkm-fluxOnly-cells.png"), height=12,width=5)
  
  ggplot(df.flux.ratio.rpkm, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFrac,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("Flux\nFraction of Cytosolic RNA-seq expr\nRPKM: cyt/(nuc + cyt)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/rpkmFlux-cells.png"), height=12,width=5)
  
  
  
  fluxBam <- merge(df.flux.ratio.rpkm,df.lpa.ratio.rpkm,by="cellGene",suffixes=c(".flux",".rfb"))
  ggplot(fluxBam, aes(x=log10(2*value.ave.nuc.flux),y=log10(2*value.ave.nuc.rfb)))+ geom_point(alpha=I(0.2)) +
    theme_bw() + thisTheme +
    facet_grid(cell.flux~.) +
    geom_abline(intercept=0,slope=1) + 
    xlab("Flux Nucleus Sum RPKM") + ylab("RPKMFromBam  Nucleus Sum RPKM")+
    ggtitle("Comparison of Flux and RPKMFromBam\nSum RPKM in Nucleus")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/fluxVRPkmFromBam-nuc-cells.png"), height=12,width=5)

  ggplot(fluxBam, aes(x=log10(value.ave.cyt.flux),y=log10(value.ave.cyt.rfb)))+ geom_point(alpha=I(0.2)) +
    theme_bw() + thisTheme +
    facet_grid(cell.flux~.) +
    geom_abline(intercept=0,slope=1)+ 
    xlab("Flux Cytosol Sum RPKM") + ylab("RPKMFromBam Cytosol Sum RPKM")+
    ggtitle("Comparison of Flux and RPKMFromBam\nSum RPKM in Cytosol")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/fluxVRPkmFromBam-cyt-cells.png"), height=12,width=5)
  
  ggplot(fluxBam, aes(x=cytFrac.flux,y=cytFrac.rfb,color=region.nuc.flux))+ geom_point(alpha=I(0.6)) +
    theme_bw() + thisTheme +
    facet_grid(cell.flux~.) +
    geom_abline(intercept=0,slope=1) + 
    xlab("Flux Nucleus cyt frac.") + ylab("RPKMFromBam  Nucleus cyt frac")+
    ggtitle("Comparison of Flux and RPKMFromBam\ncyt fraction = cyt/(cyt + nuc)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/fluxVRPkmFromBam-cytFrac-cells.png"), height=12,width=5)
  
  #RPKM80
  df.flux.ratio.rpkm80 <- df.flux.ratio.pos[which(df.flux.ratio.pos$variable =="RPKM_80norm"),]
  df.flux.ratio.rpkm80$cellGene <- with(df.flux.ratio.rpkm80,paste(gene_id,cell))
  
  
  
  df.lpa.ratio.rpkm80 <- df.cytNuc.pos[which(df.cytNuc.pos$variable =="RPKM_80norm"),]
  df.lpa.ratio.rpkm80$cellGene <- with(df.lpa.ratio.rpkm80,paste(gene_id,cell))
  bam.cells <- unique(df.lpa.ratio.rpkm$cell)
  
  df.flux.ratio.rpkm80 <- df.flux.ratio.rpkm80[which(df.flux.ratio.rpkm80$cell %in% unique(df.lpa.ratio.rpkm$cell)),]
  
  df.lpa.ratio.rpkm80 <- df.lpa.ratio.rpkm80[which(df.lpa.ratio.rpkm80$cellGene %in%  df.flux.ratio.rpkm$cellGene),]
  
  ggplot(df.lpa.ratio.rpkm80, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFracPseudo,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("RPKMfromBAM same trans in cell type\nFraction of Cytosolic RNA-seq expr\nRPKM80: cytPseudo/(nucPseudo + cytPseudo)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/rpkm80Pseudo-fluxOnly-cells.png"), height=12,width=5)
  
  ggplot(df.flux.ratio.rpkm80, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFracPseudo,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("Flux\nFraction of Cytosolic RNA-seq expr\nRPKM80: cytPseudo/(nucPseudo + cytPseudo)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/rpkm80PseudoFlux-cells.png"), height=12,width=5)
  
  
  ggplot(df.lpa.ratio.rpkm80, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFrac,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("RPKMfromBAM\nFraction of Cytosolic RNA-seq expr\nRPKM80: cyt/(nuc + cyt)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/rpkm80-fluxOnly-cells.png"), height=12,width=5)
  
  ggplot(df.flux.ratio.rpkm80, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFrac,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("Flux\nFraction of Cytosolic RNA-seq expr\nRPKM: cyt/(nuc + cyt)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/rpkm80Flux-cells.png"), height=12,width=5)
  
  
  
  fluxBam80 <- merge(df.flux.ratio.rpkm80,df.lpa.ratio.rpkm80,by="cellGene",suffixes=c(".flux",".rfb"))
  ggplot(fluxBam80, aes(x=log10(2*value.ave.nuc.flux),y=log10(2*value.ave.nuc.rfb)))+ geom_point(alpha=I(0.2)) +
    theme_bw() + thisTheme +
    facet_grid(cell.flux~.) +
    geom_abline(intercept=0,slope=1) + 
    xlab("Flux Nucleus Sum RPKM80") + ylab("RPKMFromBam  Nucleus Sum RPKM80")+
    ggtitle("Comparison of Flux and RPKMFromBam\nSum RPKM in Nucleus")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/fluxVRPkmFromBam80-nuc-cells.png"), height=12,width=5)
  
  ggplot(fluxBam, aes(x=log10(value.ave.cyt.flux),y=log10(value.ave.cyt.rfb)))+ geom_point(alpha=I(0.2)) +
    theme_bw() + thisTheme +
    facet_grid(cell.flux~.) +
    geom_abline(intercept=0,slope=1)+ 
    xlab("Flux Cytosol Sum RPKM80") + ylab("RPKMFromBam Cytosol Sum RPKM80")+
    ggtitle("Comparison of Flux and RPKMFromBam\nSum RPKM in Cytosol")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/fluxVRPkmFromBam80-cyt-cells.png"), height=12,width=5)
  
  ggplot(fluxBam, aes(x=cytFrac.flux,y=cytFrac.rfb,color=region.nuc.flux))+ geom_point(alpha=I(0.6)) +
    theme_bw() + thisTheme +
    facet_grid(cell.flux~.) +
    geom_abline(intercept=0,slope=1) + 
    xlab("Flux Nucleus cyt frac. RPKM80") + ylab("RPKMFromBam  Nucleus cyt frac RPKM80")+
    ggtitle("Comparison of Flux and RPKMFromBam\ncyt fraction = cyt/(cyt + nuc)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/fluxVRPkmFromBam80-cytFrac-cells.png"), height=12,width=5)
  
  
  
  df.flux.ratio.reads <- df.flux.ratio.pos[which(df.flux.ratio.pos$variable =="transcriptTotalReads"),]
  df.flux.ratio.reads$cellGene <- with(df.flux.ratio.reads,paste(gene_id,cell))

  ggplot(df.flux.ratio.reads, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFracPseudo,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("FLUX \nFraction of Cytosolic RNA-seq expr\nREADS: cytPseudo/(nucPseudo + cytPseudo)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/readsPseudo-flux-cells.png"), height=12,width=5)
  
  ggplot(df.flux.ratio.reads, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFrac,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("FLUX type\nFraction of Cytosolic RNA-seq expr\nREADS: cytPseudo/(nucPseudo + cytPseudo)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/reads-flux-cells.png"), height=12,width=5)
  
  
  df.cytNuc.read <- read.csv(sep="\t",file=getFullPath("data/rpkmFromBam-TopTransCellType-Reads-Proc.tab"))
  df.cytNuc.read$cytFracPseudo <- with(df.cytNuc.read, (value.rep1.pseudo.cyt+value.rep2.pseudo.cyt)/(value.rep1.pseudo.cyt + value.rep2.pseudo.cyt + value.rep1.pseudo.nuc + value.rep2.pseudo.nuc))
  df.cytNuc.read$cytFrac <- with(df.cytNuc.read, (value.ave.cyt)/(value.ave.cyt + value.ave.nuc))
  df.cytNuc.read.pos <- df.cytNuc.read[which(df.cytNuc.read$value.ave.cyt != 0 & df.cytNuc.read$value.ave.nuc != 0),]
  df.lpa.ratio.reads <- df.cytNuc.read.pos[which(df.cytNuc.read.pos$variable =="reads"),]
  df.lpa.ratio.reads$cellGene <- with(df.lpa.ratio.reads,paste(gene_id,cell))
  df.lpa.ratio.reads <- df.lpa.ratio.reads[which(df.lpa.ratio.reads$cellGene %in%  df.flux.ratio.rpkm$cellGene),]
  
  ggplot(df.lpa.ratio.reads, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFracPseudo,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("RPKMfromBAM same trans in cell type\nFraction of Cytosolic RNA-seq expr\nREADS: cytPseudo/(nucPseudo + cytPseudo)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/readsPseudo-rpkmFromBam-fluxOnly-cells.png"), height=12,width=5)
  
  ggplot(df.lpa.ratio.reads, aes(y=log10(value.ave.cyt*2 + value.ave.nuc*2),x=cytFrac,color=factor(region.cyt)))+
    geom_density2d() + theme_bw() + thisTheme + 
    facet_grid(cell~region.cyt)+
    ggtitle("RPKMfromBAM same trans in cell type\nFraction of Cytosolic RNA-seq expr\nREADS: cytPseudo/(nucPseudo + cytPseudo)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/reads-rpkmFromBam-fluxOnly-cells.png"), height=12,width=5)
  
  
  
  fluxBamReads <- merge(df.flux.ratio.reads,df.lpa.ratio.reads,by="cellGene",suffixes=c(".flux",".rfb"))
  ggplot(fluxBamReads, aes(x=log10(2*value.ave.nuc.flux),y=log10(2*value.ave.nuc.rfb)))+ geom_point(alpha=I(0.2)) +
    theme_bw() + thisTheme +
    facet_grid(cell.flux~.) +
    geom_abline(intercept=0,slope=1) + 
    xlab("Flux Nucleus Sum Reads") + ylab("RPKMFromBam  Nucleus Sum Reads")+
    ggtitle("Comparison of Flux and RPKMFromBam\nSum RPKM in Nucleus")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/fluxVRPkmFromBam-READS-nuc-cells.png"), height=12,width=5)
  
  ggplot(fluxBamReads, aes(x=log10(value.ave.cyt.flux),y=log10(value.ave.cyt.rfb)))+ geom_point(alpha=I(0.2)) +
    theme_bw() + thisTheme +
    facet_grid(cell.flux~.) +
    geom_abline(intercept=0,slope=1)+ 
    xlab("Flux Cytosol Sum RPKM80") + ylab("RPKMFromBam Cytosol Sum RPKM80")+
    ggtitle("Comparison of Flux and RPKMFromBam\nSum RPKM in Cytosol")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/fluxVRPkmFromBam-READS-cyt-cells.png"), height=12,width=5)
  
  ggplot(fluxBam, aes(x=cytFrac.flux,y=cytFrac.rfb,color=region.nuc.flux))+ geom_point(alpha=I(0.6)) +
    theme_bw() + thisTheme +
    facet_grid(cell.flux~.) +
    geom_abline(intercept=0,slope=1) + 
    xlab("Flux Nucleus cyt frac. RPKM80") + ylab("RPKMFromBam  Nucleus cyt frac RPKM80")+
    ggtitle("Comparison of Flux and RPKMFromBam\ncyt fraction = cyt/(cyt + nuc)")
  ggsave(getFullPath("plots/rnaExpr/mappedReads/RPKMfromBamTopTrans/cytFrac/fluxVRPkmFromBam-READS-cytFrac-cells.png"), height=12,width=5)
  
  
  
  
}