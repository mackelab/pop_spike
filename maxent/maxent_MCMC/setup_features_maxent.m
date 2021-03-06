function [fvals,description,x]=setup_features_maxent(x,map)
%calculature features for max-ent model fitting
%first argument: the vectors to which the feature maps should be supplied
%if the first argument is a single integer, then the function generates all
%binary vectors {0,1} with that many elements, 
%
%inputs: 
%x: either a matrix of size N-by-d, where each row is a vector of
%data-points (usually binary), or an integer (size(x) = [1,1]). 
%In the latter case, x is interpreted as the dimensionality of a binary
%space and fevals will be evaluated at all 2^x points within that space
%
%map: either integers 1, 2, 3, ('first', 'second', 'third-order' maxent),
% or 'ising' (same as 2) or 'ising_count' for ising model with additional 
%constraints on the total activity count
%or a function handle for using user-supplied feature maps
%
%outputs:
%fvals, the calculated features. If map=1, then same as x, if map=2, this
%is a copy of x concatenated with all two-tupels without repetion, if
%map=3, then this is further concatenated with all three-tupels without
%any repetions. (Note that this is NOT what you might want if x is
%different from a binary (0,1) repetiation, as I am excluding all the x.^2,
%and x.^3 features etc, as they are redundant in this representation!

% function adapted from the pop_spike code base 
% https://bitbucket.org/mackelab/pop_spike

[N,d]=size(x);
if (N==d) && (N==1);
    d=x;
    N=2^d;
    x=(0:(N-1))';
    x=DecToBin(x);
   % if nargin==3 && convention==-1
   %     x=2*x-1;
   % end
end

if mean(x(:)==0)>.5
x=sparse(x);
end

switch map
    case 1
        fvals=x;
        description=[1:d];
    case {2,'ising'}
        pairs=nchoosek(1:d,2)';
        description=[[1:d; (1:d)*nan],pairs];  
        fvals=[x,x(:,pairs(1,:)).*x(:,pairs(2,:))];
    case 3
        pairs=nchoosek(1:d,2)';
        triplets=nchoosek(1:d,3)';
        description=[[1:d; (1:d)*nan;(1:d)*nan],[pairs; pairs(1,:)*nan],triplets];  
        fvals=[x,x(:,pairs(1,:)).*x(:,pairs(2,:)),x(:,triplets(1,:)).*x(:,triplets(2,:)).*x(:,triplets(3,:))];
    case 'ising_count'
        pairs=nchoosek(1:d,2)';
        count_indicators=zeros(N,d);
        sum_x=sum(x,2);
        nonzero=find(sum_x>0);
        ind=sub2ind([N,d],nonzero,sum_x(nonzero));
        count_indicators(ind)=1;
        description=[[1:d; (1:d)*nan],pairs,[1:d; (1:d)*nan]];  
        fvals=[x,x(:,pairs(1,:)).*x(:,pairs(2,:)),count_indicators];
        %keyboard
    case 'k_pairwise' % same as 'ising_count', but has feature for K=0
        pairs=nchoosek(1:d,2)';
        count_indicators=zeros(N,d+1);
        ind=sub2ind([N,d+1],(1:N)',sum(x,2)+1);
        count_indicators(ind)=1;
        description=[[1:d; (1:d)*nan],pairs,[0:d; (0:d)*nan]];  
        fvals=[x,x(:,pairs(1,:)).*x(:,pairs(2,:)),count_indicators];
    otherwise
        fvals=feval(map,x);
        description='custom map, no description available';
        
end

