#!/bin/env Rscript
#This script is to get the slope of recovery of pi and the number of  base pairs that would lead to 50%, 75% and 90% recovery for a given recombination rate.
#I'm here multiplying both the recombination and gene conversion rate by 0.5, just to see more of an effect of demography.


#Define constants needed from the user:
g <- 0.5*1e-8 #1e-8 #rate of gene conversion
tract_len <- 440 #mean tract length of gene conversion in base pairs
r <- 0.5*1.0*1e-8 #rate of recombination
l <- 10000.0 #(*Length of genomic element*)
u <- 3.0*1e-9 #(*Mutation rate*)
#Parameters of instantaneous change in demographic history:
Nanc <- 1e6 #(Ancestral population size)
Ncur <- 1e6 #(Current population size)
TIME <- "T_0_5" #T_0_1/T_0_5/T_1
time_of_change <- 0.0 #0.1/0.5/1(This is the time of change in 2Ncur generations in the past.)
#Parameters of the DFE:
DFE <- "DFE1"
f0 <- 0.1 #(*Proportion of effectively neutral mutations with 0 <= |2Nes| < 1 *)
f1 <- 0.7 #(*Proportion of weakly deleterious mutations with 1 <= |2Nes| < 10 *)
f2 <- 0.1 #(*Proportion of moderately deleterious mutations with 10 <= |2Nes| < 100 *)
f3 <- 0.1 #(*Proportion of strongly deleterious mutations with |2Nes| >= 100 *)
#(*Note that the number of classes can easily be increased to whatever is required to approximate the continuous DFE *)
h <- 0.5 #(* dominance coefficient, default can be 0.5 *)
s_window_size <- 100

#Constants that we do not need from the user:
U <- l*u
gamma_cutoff <- 2.0
pi_anc <- 4*Nanc*u #(*Expected nucleotide diversity under neutrality*)
#(*Now we define the boundaries of the fixed intervals over which we will integrate *)
t0 <- 0.0
t1 <- h*(1/(2*Nanc))
t1half <- h*(gamma_cutoff/(2*Nanc)) #(* This is the cut-off value of 2Nes=5. This derivation assumes that all mutations with 2Nes<5 will not contribute to BGS *)
t2 <- h*(10/(2*Nanc))
t3 <- h*(100/(2*Nanc))
t4 <- h*1.0

calculate_a_and_b <- function(posn){
    C <- (1.0 - exp(-2.0*r*posn))/2.0
    if (g == 0){
        a <- C
        b <- C + r*l
    }
    else if (g > 0.0){
        if (posn+l < 0.5*tract_len){#The 0.5 is currently aribtrary. It's just about when the approximation of 1-exp(-x)~x holds. 
            #print ("accounting for small-distance gene conversion")
            a <- (C + (g*posn))
            b <- (C + r*l + (g*(posn+l)))
	}
        else{
            #print ("accounting for large-distance gene conversion")
            a <- g*tract_len + C
            b <- g*tract_len + r*l + C
	}
    }
    return (c(a, b))
}

calculate_exponent <- function(t_start, t_end, posn){
    t_tmp <- calculate_a_and_b(posn)
    a <- as.numeric(t_tmp[1])
    b <- as.numeric(t_tmp[2])
    E1 <- ((U*a)/((1-a)*(a-b)*(t_end-t_start))) * log((a+(t_end*(1-a)))/(a + (t_start*(1-a))))
    E2 <- -1.0*((U*b)/((1-b)*(a-b)*(t_end-t_start)))*log((b + ((1-b)*t_end))/(b + ((1-b)*t_start)))
    E <- E1 + E2
    return (E)
}

calculate_B <- function(posn){
    E_f1 <- calculate_exponent(t1half, t2, posn) 
    E_f2 <- calculate_exponent(t2, t3, posn)
    E_f3 <- calculate_exponent(t3, t4, posn)
    E_bar <- f0*0.0 + f1*((t1half-t1)/(t2-t1))*0.0 + f1*((t2-t1half)/(t2-t1))*E_f1 + f2*E_f2 + f3*E_f3
    B <- exp(-1.0*E_bar)
    return (B)
}


calculate_pi <- function(posn){
    pi_posn <- pi*calculate_B(posn)
    return (pi_posn)
}

calculate_pi_window <- function(win_start, win_end){
    i <- win_start
    pi_sum <- 0.0
    while (i <= win_end){
        pi_sum <- pi_sum + calculate_pi(i)
        i <- i + 1
    }
    return(pi_sum/(win_end - win_start+1))
}

calculate_Banc_window <- function(win_start, win_end){
    i <- win_start
    B_sum <- 0.0
    while (i <= win_end){
        B_sum <- B_sum + calculate_B(i)
        i <- i + 1
    }
    return(B_sum/(win_end - win_start+1))
}

get_Bcur <- function(Banc){
    R <- Nanc/Ncur
    Bcur <- (Banc*(1.0 + (R-1.0)*exp((-1.0*time_of_change)/Banc))) / (1 + (R-1.0)*exp(-1.0*time_of_change))
    return (Bcur)
}
                                                                                
#Getting an average pi over a window:
#Output would need to be 3 columns: v_start, v_end, and v_B
v_start <- c()
v_end <- c()
v_B <- c()
posn_start <- 1
len_intergenic <- 10000 #fixed constant that can be changed later
posn_start <- 1
while (posn_start <= len_intergenic){
    v_start <- c(v_start, posn_start)
    v_end <- c(v_end, posn_start+s_window_size-1)
    v_B <- c(v_B, get_Bcur(calculate_Banc_window(posn_start, posn_start+s_window_size)))
    posn_start <- posn_start + s_window_size
    #print(calculate_Banc_window(posn_start, posn_start+s_window_size))
}
print (v_start)
print(v_end)
print(v_B)
print("done")


