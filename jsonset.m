function json=jsonset(fname,mmap,varargin)
%
% json=jsonset(fname,mmap,'$.jsonpath1',newval1,'$.jsonpath2','newval2',...)
%
% Fast writing of JSON data records to stream or disk using memory-map 
% (mmap) returned by loadjson and JSONPath-like keys
%
% authors:Qianqian Fang (q.fang <at> neu.edu)
% initially created on 2022/02/02
%
% input:
%      fname: a JSON/BJData/UBJSON string or stream, or a file name
%      mmap: memory-map returned by loadjson/loadbj of the same data
%            important: mmap must be produced from the same file/string,
%            otherwise calling this function may cause data corruption
%      '$.jsonpath1,2,3,...':  a series of strings in the form of JSONPath
%            as the key to each of the record to be written
%
% output:
%      json: the modified JSON string or, in the case fname is a filename,
%            the cell string made of jsonpaths that are successfully
%            written
%
% examples:
%      str='[[1,2],"a",{"c":2}]{"k":"test"}';
%      [dat, mmap]=loadjson(str);
%      savejson('',dat,'filename','mydata.json','compact',1);
%      json=jsonset(str,mmap,'$.[2].c','5')
%      json=jsonset('mydata.json',mmap,'$.[2].c','"c":5')
%
% license:
%     BSD or GPL version 3, see LICENSE_{BSD,GPLv3}.txt files for details 
%
% -- this function is part of JSONLab toolbox (http://iso2mesh.sf.net/cgi-bin/index.cgi?jsonlab)
%

if(regexp(fname,'^\s*(?:\[.*\])|(?:\{.*\})\s*$','once'))
    inputstr=fname;
else
    fid=fopen(fname,'wb');
end

mmap=[mmap{:}];
keylist=mmap(1:2:end);

opt=struct;
for i=1:2:length(varargin)
    if(isempty(regexp(varargin{i},'^\$', 'once')))
        opt.(encodevarname(varargin{i}))=varargin{i+1};
    end
end

json={};
for i=1:2:length(varargin)
    if(regexp(varargin{i},'^\$'))
        [tf,loc]=ismember(varargin{i},keylist);
        if(tf)
            rec={'uint8',[1,mmap{loc*2}(2)],  'x'};
            if(ischar(varargin{i+1}))
                val=varargin{i+1};
            else
                val=savejson('',varargin{i+1},'compact',1);
            end
            if(length(val)<=rec{1,2}(2))
                val=[val repmat(' ',[1,rec{1,2}(2)-length(val)])];
                if(exist('inputstr','var'))
                    inputstr(mmap{loc*2}(1):mmap{loc*2}(1)+mmap{loc*2}(2)-1)=val;
                else
                    if(exist('memmapfile','file'))
                        fmap=memmapfile(fname,'writable',true,'offset',mmap{loc*2}(1),'format', rec);
                        fmap.x=val;
                    else
                        fseek(fid,mmap{loc*2}(1)-1,'bof');
                        fwrite(fid,val);
                    end
                    json{end+1}={varargin{i},val};
                end
            end
        end
    end
end

if(exist('fid','var') && fid>=0)
    fclose(fid);
end

if(exist('inputstr','var'))
    json=inputstr;
end
