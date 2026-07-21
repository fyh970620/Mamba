% 海洋电磁快速反演系统
% 基于Matlab GUI开发的关于海洋可控源电磁勘探技术（CSEM）的综合处理软件。
%
% 作者：郭振威
% 中南大学地球科学与信息物理学院
%
%
%
% 用于一维、二维海底地质体的电阻率建模，
% 生成海洋可控源电磁正演的数据文件、生成多种反演网格，
% 增加根据地震图像的相干度提取特征点构建基于相干度的不规则系数网格
% 增加由地震图像引导的正则化CSEM反演。
function [ D,Tensor ] = metrictensor( imgI )

    %%% 输入一个D（x）
    % 计算结构张量
    si=1; so=1;
    [Sxx, Sxy, Syy] = structureTensor(imgI,si,so);
    %计算度量张量
    [rows, cols] = size(imgI);
    S=cell(rows,cols);
    coherence=zeros(rows,cols);
    Dx=cell(rows,cols);
    D=cell(rows,cols);
    Tensor.l1=zeros(rows,cols);
    Tensor.l2=zeros(rows,cols);
    Tensor.l3=zeros(rows,cols);
    Tensor.l4=zeros(rows,cols); 
    Tensor.vector1=zeros(rows,cols);
    Tensor.vector2=zeros(rows,cols);     
    tic;
    epsol=0.0001;
    for i=1:rows;
        for j=1:cols;
            S{i,j}=[Sxx(i,j),Sxy(i,j);Sxy(i,j),Syy(i,j)];
            [e1,e2,l1,l2] = eigen_decomposition(S{i,j});
              Tensor.l1(i,j)=l1; Tensor.l2(i,j)=l2;
              if (l1+l2) > 0
                coherence(i,j) = ((l1-l2)/(l1+l2))^2;
              else
                coherence(i,j) = 0;
              end
           Dx{i,j} = pinv(S{i,j});
           if (coherence(i,j)>=0 && coherence(i,j) <1)
              D{i,j} = Dx{i,j}/(1-coherence(i,j));
           else
             disp('The coherence is wrong') 
             disp(['i:',num2str(i),'j:',num2str(j)]);
             D{i,j} = imgI(i,j)*[1,0;0,1];
           end
           [e3,e4,l3,l4] = eigen_decomposition(S{i,j});
            Tensor.l3(i,j)=l3; Tensor.l4(i,j)=l4;
            Tensor.vector1=e3; Tensor.vector2=e4;            
        end
    end
    %时间成本
    time1 = toc;
    disp(['Time:',num2str(time1),'s']);
    %度量张量场
    Dxx=zeros(rows,cols);
    Dxy=zeros(rows,cols);
    Dyy=zeros(rows,cols);
    for j=1:cols;
        for i=1:rows;
           Dxx(i,j)=D{i,j}(1,1);
           Dxy(i,j)=D{i,j}(1,2);
           Dyy(i,j)=D{i,j}(2,2);
        end
    end


end

