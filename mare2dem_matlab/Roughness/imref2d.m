
% 海洋电磁快速反演系统
% 基于Matlab GUI开发的关于海洋可控源电磁勘探技术（CSEM）的综合处理软件。
%
% 作者：郭振威
% 中南大学地球科学与信息物理学院
%
%
%
%Imref2D将2-D图像参照到世界坐标
%
%Imref2D对象封装了固定到2-D图像的列和行的\“固有
%坐标\”与世界坐标系中相同行和列位置的空间位置之间的关系。
%图像在坐标系统的平面\“WORLD%X\”和\“WORLD Y\”坐标中定期采样，以便
%\“固有X\”和\“世界X\”轴对齐，并且同样与\“固有
%Y\”和\“世界Y\”轴对齐。行到行中的像素间距不需要等于列到列中的像素间距。
%
% 任何像素的中心点的固有坐标值(x，y)与该
%像素的列和行下标的值相同。例如，第5行3
%列中像素的中心点具有固有坐标x=3.0，y=5.0。但是，请注意，坐标规范的
%顺序(3.0，5.0)在内部%坐标中相对于像素下标(5，3)是相反的。固有坐标
%定义在连续平面上，而下标位置是具有整数值的%离散位置。
%
%   Imref2d属性:
%      XWorldLimits - Limits of image in world X [xMin xMax]
%      YWorldLimits - Limits of image in world Y [yMin yMax]
%      ImageSize - Image size in each spatial dimension
%
%   imref2d 性能 (SetAccess = private):
%      PixelExtentInWorldX - Spacing along rows in world units
%      PixelExtentInWorldY - Spacing along columns in world units
%      ImageExtentInWorldX - Full image extent in X dimension
%      ImageExtentInWorldY - Full image extent in Y dimension
%      XIntrinsicLimits - Limits of image in intrinsic X [xMin xMax]
%      YIntrinsicLimits - Limits of image in intrinsic Y [yMin yMax]
%
%   imref2d 方法:
%      imref2d - 构造imref2d对象
%      sizesMatch - 如果对象和图像大小兼容，则为True
%      intrinsicToWorld - 从固有坐标转换为世界坐标
%      worldToIntrinsic - 将世界坐标转换为固有坐标
%      worldToSubscript - 行和列下标的世界坐标
%      contains - 如果图像包含世界坐标系中的点，则为True
% 
%   Example 1
%   ---------
%   % 在已知世界极限和图像大小的情况下构造imref2D对象.
%   A = imread('pout.tif');
%   xWorldLimits = [2 5];
%   yWorldLimits = [3 6];
%   RA = imref2d(size(A),xWorldLimits,yWorldLimits);
%   % 以imshow％数字显示空间参考图像，imshow（A，RA）
%
%   Example 2
%   ---------
%   % 给定每个尺寸和图像大小的分辨率知识，构造一个imref2d对象
%   m = dicominfo('knee1.dcm');
%   A = dicomread(m);
%   % 文件元数据的PixelSpacing字段以毫米/像素为单位指定每个维度中的分辨率。
    %  使用此信息来构建与图像数据A关联的空间参考对象。
%   RA = imref2d(size(A),m.PixelSpacing(2),m.PixelSpacing(1));
%   %检查每个维度中图像的范围，以毫米为单位
%   RA.ImageExtentInWorldX
%   RA.ImageExtentInWorldY
%   





classdef imref2d
    
    
    
    properties (Dependent = true)
        
        %XWorldLimits-世界中图像的限制X[xMin xMax]
        %
        %    XWorldLimits是一个由两个元素组成的行向量。
        XWorldLimits
        
        %YWorldLimits - 世界Y中的图像极限[yMin yMax]
        %
        %    YWorldLimits是一个两元素行向量.
        YWorldLimits
        
        %每个空间维度中元素的ImageSize数量
        %
        %   ImageSize是一个指定图像大小的矢量
        %   与引用对象关联.
        ImageSize
        
    end
    
    properties(Dependent=true,SetAccess = protected)

        %PixelExtentInWorldX-以世界为单位沿行的像素范围.
        PixelExtentInWorldX
        
        %PixelExtentInWorldX-以世界为单位沿行的像素范围.
        PixelExtentInWorldY
        
    end
    
    properties(Dependent=true,SetAccess = private)
       
        
        %ImageExtentInWorldX-X方向的完整图像范围
        %
        % ImageExtentInWorldX是图像的范围，以世界系统在X方向上的百分比为单位测量。
        ImageExtentInWorldX
        
        %ImageExtentInWorldY-Y方向的完整图像范围
        %
        %ImageExtentInWorldY是图像的范围，以世界系统在Y方向上的百分比为单位测量。
        ImageExtentInWorldY
                
        %XIntrinsicLimits-固有X中图像的极限[xMin xMax]
        %
        % XIntrinsicLimits是一个由两个元素组成的行向量。对于M-x-N
        %    image (or an M-by-N-by-P image) it equals [0.5, N + 0.5].
        XIntrinsicLimits
        
        %YIntrinsicLimits-图像在本征Y中的极限[yMin yMax]
        %
        %    YIntrinsicLimits-图像在本征Y中的极限[yMin yMax]
        %    image (or an M-by-N-by-P image) it equals [0.5, M + 0.5].
        YIntrinsicLimits
         
    end
    
    
    %---------------- Properties: Protected + hidden ---------------------
    properties (Access = protected, Hidden = true)
        
        Dimension
        
    end
    
    properties (SetAccess = private, Hidden = true)
        
        %FirstCornerX-图像第一个角的世界X坐标
        %
        %R.FirstCornerX返回与参考对象R关联的图像的第一个像素的
        %最外角的世界X坐标。此世界X位置%对应于固有的X位置0.5。
        
      
        %  R.FirstCornerY返回与参考对象R关联的图像的第一个像素的
        %最外角的世界Y坐标。此世界Y位置对应于固有的Y位置0.5。
        FirstCornerY
                
    end
    

    
    %-------------- 构造函数和普通方法 -------------------
    
    methods
                   
                   
        function self = imref2d(imageSize, varargin)
            %Imref2d构造imref2d对象
            %
            %   R = imref2d() 使用默认的属性设置构造imref2d对象。
            %
            %  R=imref2d(ImageSize)构造给定图像大小百分比的imref2d对象。
            % 此语法针对世界坐标系与固有坐标系共同对齐的默认情况构建空间参考对象。
            %
            % R=imref2d(ImageSize，PixelExtentInWorldX，PixelExtentInWorldY)
            % 构造imref2d对象，给定图像大小和每个维度中由标量
            % PixelExtentInWorldX和PixelExtentInWorldY定义的分辨率。
            %
            % R=imref2d(ImageSize，PixelExtentInWorldX，PixelExtentInWorldY)
            %构造imref2d对象，给定图像大小和每个维度中由标量
            %PixelExtentInWorldX和PixelExtentInWorldY定义的分辨率。
             
            % R=imref2d(ImageSize，PixelExtentInWorldX，PixelExtentInWorldY)
            %构造imref2d对象，给定图像大小和每个维度中由标量PixelExtentInWorldX和PixelExtentInWorldY定义的分辨率。
            validSyntaxThatSpecifiesImageSize = (nargin == 1) || (nargin == 3);
            if validSyntaxThatSpecifiesImageSize
                validateattributes(imageSize, ...
                    {'double'}, {'positive','real','vector','integer','finite'}, ...
                    'imref2d', ...
                    'ImageSize');
                if isscalar(imageSize)
                    error(message('images:spatialref:invalidImageSize','ImageSize'));
                end
            end
            
            if (nargin ==0)
                % imref2d()
                self.Dimension.X = images.spatialref.internal.SpatialDimensionManager('X');
                self.Dimension.Y = images.spatialref.internal.SpatialDimensionManager('Y');
            elseif (nargin == 1)
                % imref2d(imageSize)
                self.Dimension.X = images.spatialref.internal.SpatialDimensionManager('X',imageSize(2),1,0.5);
                self.Dimension.Y = images.spatialref.internal.SpatialDimensionManager('Y',imageSize(1),1,0.5);
            else
                narginchk(3,3);

                if isscalar(varargin{1})
                    % imref2d(imageSize,pixelExtentInWorldX,pixelExtentInWorldY)
                    pixelExtentInWorldX = varargin{1};
                    pixelExtentInWorldY = varargin{2};
                    self.Dimension.X = images.spatialref.internal.SpatialDimensionManager('X',imageSize(2),pixelExtentInWorldX,pixelExtentInWorldX/2);
                    self.Dimension.Y = images.spatialref.internal.SpatialDimensionManager('Y',imageSize(1),pixelExtentInWorldY,pixelExtentInWorldY/2);
                else
                    % imref2d(imageSize,xWorldLimits,yWorldLimits)
                    self.Dimension.X = images.spatialref.internal.SpatialDimensionManager('X',imageSize(2),1,0.5);
                    self.Dimension.Y = images.spatialref.internal.SpatialDimensionManager('Y',imageSize(1),1,0.5);
                    self.XWorldLimits = varargin{1};
                    self.YWorldLimits = varargin{2};
                end
                
            end
            
        end
        
        
        function [xw,yw] = intrinsicToWorld(self,xIntrinsic,yIntrinsic)
            %InterinsicToWorld从固有坐标转换为世界百分比坐标
            %
            %   [xWorld, yWorld] = intrinsicToWorld(R,...
            %   xIntrinsic,yIntrinsic) 
            
            validateXYPoints(xIntrinsic,yIntrinsic,'xIntrinsic','yIntrinsic');
            
            xw = self.Dimension.X.intrinsicToWorld(xIntrinsic);
            yw = self.Dimension.Y.intrinsicToWorld(yIntrinsic);
        end
        
        function [xi,yi] = worldToIntrinsic(self,xWorld,yWorld)
            %InterinsicToWorld从固有坐标转换为世界百分比坐标
            %
            %  [x固有的，y固有的]=world到固有的(R，...。
               %xWorld，yWorld)根据引用对象R定义的关系%将点位置从
             %world系统(xWorld，yWorld)映射到内部
             %system(xIntrintive，yIntrintive)。输入可能%包括完全超出世界系统中图像
             %限制的值。在这种情况下，世界X和Y%被外推到%固有系统中图像的边界之外。
            
            validateXYPoints(xWorld,yWorld,'xWorld','yWorld');
            
            xi = self.Dimension.X.worldToIntrinsic(xWorld);
            yi = self.Dimension.Y.worldToIntrinsic(yWorld);
        end
        
        function [r,c] = worldToSubscript(self,xWorld,yWorld)
           
            %
            % [I，J]=WorldToSubscript(R，xWorld，yWorld)根据引用对象R定义的关系，将点
            %位置从世界系统(xWorld，yWorld)映射到下标数组I和J。I和J是图像像素的行和列
            %下标，该图像像素包含给定世界坐标(xWorld，yWorld)的%点集的每个元素。XWorld和yWorld的大小必须相同。I和J
            %的大小将与xWorld和yWorld相同。对于M乘以N的图像，1&lt;=I&lt;=M和1&lt;=J&lt;=N，除非点xWorld(K)，yWorld(K)落在图像之外，如
            %CONTAINS(R，xWorld，yWorld)所定义，则I(K)和J(K)都是NaN。
            
            validateXYPoints(xWorld,yWorld,'xWorld','yWorld');
            
            r = self.Dimension.Y.worldToSubscript(yWorld);
            c = self.Dimension.X.worldToSubscript(xWorld);
            
            nan_r = isnan(r);
            nan_c = isnan(c);
            
            % 行或列为NaN的任何[r，c]都需要作为%对NaN。
            c(nan_r) = NaN;
            r(nan_c) = NaN;
        end
        
        function TF = contains(self,xWorld,yWorld)
            %如果图像包含世界坐标系中的点，则包含True
            %
            %TF=CONTAINS(R，xWorld，yWorld)返回与xWorld，yWorld大小相同的逻辑数组Tf
            %，当且仅当点(xWorld(K)，yWorld(K))落在与引用对象R关联的图像的边界内时，TF(K)为
            %TRUE。
            
            validateXYPoints(xWorld,yWorld,'xWorld','yWorld');
            
            TF = self.Dimension.X.contains(xWorld) ...
               & self.Dimension.Y.contains(yWorld);
        end
        
        function TF = sizesMatch(self,I)
            %大小匹配如果对象和图像大小兼容，则匹配True
            %
            %  如果图像A的大小与引用对象R的ImageSize属性一致，则TF=sizesMatch(R，A)返回TRUE。
            %
            %  R.ImageSize == [size(A,1) size(A,2)].
            imageSize = size(I);
            TF = isequal(imageSize(1),self.Dimension.Y.NumberOfSamples)...
              && isequal(imageSize(2),self.Dimension.X.NumberOfSamples);
        end
        
        
    end

    
    %----------------- Get methods ------------------
    methods
                
        function extentX = get.ImageExtentInWorldX(self)
            extentX = self.Dimension.X.ExtentInWorld;
        end
        
        function height = get.ImageExtentInWorldY(self)
            height = self.Dimension.Y.ExtentInWorld;
        end
        
        function limits = get.XWorldLimits(self)
            limits = self.Dimension.X.WorldLimits;
        end
        
        function limits = get.YWorldLimits(self)
            limits = self.Dimension.Y.WorldLimits;  
        end
                
        function extentX = get.PixelExtentInWorldX(self)
            extentX = abs(self.Dimension.X.Delta);
        end
        
        function extentY = get.PixelExtentInWorldY(self)
            extentY = abs(self.Dimension.Y.Delta);
        end
                        
        function xedge = get.FirstCornerX(self)
            xedge = self.Dimension.X.StartCoordinateInWorld;
        end
        
        function xedge = get.FirstCornerY(self)
            xedge = self.Dimension.Y.StartCoordinateInWorld;
        end
        
        function limits = get.XIntrinsicLimits(self)
            limits = self.Dimension.X.IntrinsicLimits;
        end
        
        function limits = get.YIntrinsicLimits(self)
            limits = self.Dimension.Y.IntrinsicLimits;
        end
        
        function imageSize = get.ImageSize(self)
            is3D = isfield(self.Dimension,'Z');
            
            if is3D
                imageSize = [self.Dimension.Y.NumberOfSamples,...
                             self.Dimension.X.NumberOfSamples,...
                             self.Dimension.Z.NumberOfSamples];
            else
                imageSize = [self.Dimension.Y.NumberOfSamples,...
                             self.Dimension.X.NumberOfSamples];
            end
                
        end
                
    end
    
    %----------------- Set methods ------------------
    methods
       
        function self = set.XWorldLimits(self, xLimWorld)
            self.Dimension.X.WorldLimits = xLimWorld;
        end
        
        function self = set.YWorldLimits(self, yLimWorld)
            self.Dimension.Y.WorldLimits = yLimWorld;
        end
               
       function self = set.ImageSize(self,imSize)
           
           validateattributes(imSize, ...
               {'double'}, {'positive','real','vector','integer','finite'}, ...
               'imref2d.set.ImageSize', ...
               'ImageSize');
           
           if isscalar(imSize)
               error(message('images:spatialref:invalidImageSize','ImageSize'));
           end
           
           self.Dimension.X.NumberOfSamples = imSize(2);
           self.Dimension.Y.NumberOfSamples = imSize(1);
          
           is3D = isfield(self.Dimension,'Z');
           if is3D
               if numel(imSize) ~=3
                   error(message('images:spatialref:invalid3dImageSize','ImageSize'));
               end
               self.Dimension.Z.NumberOfSamples = imSize(3);
           end
          
       end
       
    end
    
    % 实现saveobj和loadobj是为了确保跨版本的兼容性，即使空间参考类的体系结构发生变化。
    methods (Hidden)
       
        function S = saveobj(self)
            
            S = struct('ImageSize',self.ImageSize,...
                        'XWorldLimits',self.XWorldLimits,...
                        'YWorldLimits',self.YWorldLimits);
            
        end
        
    end
    
    methods (Static, Hidden)
       
        function self = loadobj(S)
           
            self = imref2d(S.ImageSize,S.XWorldLimits,S.YWorldLimits);
            
        end
        
    end
            
end

function validateXYPoints(X,Y,xName,yName)

if ~isequal(size(X),size(Y))
    error(message('images:spatialref:invalidXYPoint',xName,yName));
end

end
