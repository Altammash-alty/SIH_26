function out = evalReferable(scores, labels, cutoff)
%EVALREFERABLE Binary referable-DR metrics with Wilson 95% intervals.
% scores and labels are vectors; labels are logical (Grade >= 2).
    if numel(scores) ~= numel(labels) || isempty(scores)
        error('evalReferable:InputSize','scores and labels must be nonempty vectors of equal length.');
    end
    scores = scores(:);
    if islogical(labels)
        labels = labels(:);
    elseif isnumeric(labels)
        if any(labels > 1)
            labels = (labels(:) >= 2);
        else
            labels = logical(labels(:));
        end
    else
        labels = logical(labels(:));
    end
    predicted = scores >= cutoff;
    tp = sum(predicted & labels); fn = sum(~predicted & labels);
    tn = sum(~predicted & ~labels); fp = sum(predicted & ~labels);
    out = struct('n',numel(labels),'cutoff',cutoff,'sensitivity',tp/max(1,tp+fn), ...
        'specificity',tn/max(1,tn+fp),'TP',tp,'FN',fn,'TN',tn,'FP',fp, ...
        'confusion',[tn fp; fn tp], ...
        'sensitivityCI',wilson(tp,tp+fn),'specificityCI',wilson(tn,tn+fp));
end

function ci = wilson(k,n)
    if n == 0, ci = [NaN NaN]; return; end
    z = 1.95996398454005; p = k/n; d = 1+z^2/n;
    c = (p+z^2/(2*n))/d;
    h = z*sqrt(p*(1-p)/n+z^2/(4*n^2))/d;
    ci = [max(0,c-h) min(1,c+h)];
end
