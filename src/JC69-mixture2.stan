
data {
    int <lower=0> T;               // number of trees
    int <lower=0> L;               // alignment length
    int <lower=0> S;               // number of tips
    int B; // number of independent branches (not including one of the children of root)
    real<lower=0,upper=1> tipdata[S,L,4];
    int <lower=0,upper=2*S> peel[T,(S-1),3];   // list of nodes for peeling
    int indexes[(2*S-3)*T]; // -3 because we do not count one of the children of root
    real weights[L];
}

transformed data {
    int bcount; // number of branches
    int pcount;
    int alphalen;
    int root;
    vector<lower=0>[T] alpha; // could be moved to data

    bcount = 2*S-2;
    pcount = 2*S-3;
    alphalen=4; // assume DNA
     for(i in 1:T){
        alpha[i] = 1;
     }

}

parameters {
	//vector <lower=0,upper=10>[B] blens[T]; // branch lengths
	vector <lower=0,upper=10>[B] blens; // branch lengths (independent)
	simplex[T] theta;
}


model {
    vector[alphalen] node[T,2*S,L];   // partial probabilities for the S tips and S-1 internal nodes
    matrix[alphalen,alphalen] fttm[B+1]; // finite-time transition matrices for each branch, plus zero-length root branch
    real ps[T];
    int counter;

    counter = 1;

    // set some branch length priors
    blens ~ exponential(20);

    theta ~ dirichlet(alpha);

    // calculate finite time transition matrices for each branch
    // under the Jukes-Cantor model
    for( b in 1:B){
        for( i in 1:4 ) {
            for( j in 1:4 ) {
                fttm[b][i,j] = 0.25 - 0.25*exp(-4*blens[b]/3);
            }
            fttm[b][i,i] = 0.25 + 0.75*exp(-4*blens[b]/3);
        }
    }
    fttm[B+1] = rep_matrix(0,alphalen,alphalen);
    for( i in 1:alphalen ) {
        fttm[B+1][i,i] = 1;
    }

    /*for( t in 1:T){
        for( b in 1:bcount-1 ) {
            for( i in 1:alphalen ) {
                for( j in 1:alphalen ) {
                    //fttm[t,b][i,j] = 0.25 - 0.25*exp(-4*blens[t,b]/3);
                    fttm[t,b][i,j] = 0.25 - 0.25*exp(-4*blens[indexes[counter]]/3);
                }
                //fttm[t,b][i,i] = 0.25 + 0.75*exp(-4*blens[t,b]/3);
                fttm[t,b][i,i] = 0.25 + 0.75*exp(-4*blens[indexes[counter]]/3);
            }
            counter = counter + 1;
        }

        // zero-length root branch identity matrix
        fttm[t,bcount] = rep_matrix(0,alphalen,alphalen);
        for( i in 1:alphalen ) {
            fttm[t,bcount][i,i] = 1;
        }
    }*/


    // copy tip data into node probability vector
    for( t in 1:T ) {
        for( n in 1:S ) {
            for( i in 1:L ) {
                for( a in 1:alphalen ) {
                    node[t,n,i][a] = tipdata[n,i,a];
                }
            }
        }
    }

    // calculate tree likelihood for the topology encoded in peel
    /*for( t in 1:T ) {
        ps[t] = log(theta[t]);
        for( i in 1:L ) {
            for( n in 1:(S-1) ) {
                node[t,peel[t,n,3],i] = (fttm[t,n*2-1]*node[t,peel[t,n,1],i]) .* (fttm[t,n*2]*node[t,peel[t,n,2],i]);
            }
            // multiply by background nt freqs (assuming uniform here)
            node[t,2*S,i] = node[t,peel[t,S-1,3],i] / alphalen;

            // add the site log likelihood
            ps[t] = ps[t] + log(sum(node[t,2*S,i]))*weights[i];
        }
    }
    target += log_sum_exp(ps);*/

    for( i in 1:L ) {
        counter = 1;
        for( t in 1:T ) {
            ps[t] = log(theta[t]);
            for( n in 1:(S-2) ) {
                node[t,peel[t,n,3],i] = (fttm[indexes[counter]]*node[t,peel[t,n,1],i]) .* (fttm[indexes[counter+1]]*node[t,peel[t,n,2],i]);
                counter  = counter + 2;
            }
            node[t,peel[t,S-1,3],i] = (fttm[indexes[counter]]*node[t,peel[t,S-1,1],i]) .* (fttm[indexes[B+1]]*node[t,peel[t,S-1,2],i]);
            counter  = counter + 1;
            // multiply by background nt freqs (assuming uniform here)
            node[t,2*S,i] = node[t,peel[t,S-1,3],i] / alphalen;

            // add the site log likelihood
            ps[t] = ps[t] + log(sum(node[t,2*S,i]))*weights[i];
        }
        target += log_sum_exp(ps);
    }

}
