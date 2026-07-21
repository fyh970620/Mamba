% 手动构造最基础的测试数据，模拟Mamba2D的输出格式

% 1. 构造节点（4个点组成正方形）
nodes = [0 0;   % 节点1：x=0, y=0
         10 0;  % 节点2：x=10, y=0
         0 10;  % 节点3：x=0, y=10
         10 10];% 节点4：x=10, y=10

% 2. 构造三角单元（2个三角形组成正方形）
elements = [1 2 3;  % 单元1：由节点1、2、3组成
            2 4 3]; % 单元2：由节点2、4、3组成

% 3. 构造电阻率（2个单元，对应2个电阻率值）
rho = [100; 200];

% 4. 构造单元相邻关系（和Mamba2D输出格式一致）
neighbors = {[2], [1]}; % 单元1的邻居是单元2，单元2的邻居是单元1

% 5. 惩罚截断线段（空值，模拟无截断）
penalty_segs = [];

% 6. 直接调用你的 Roughness 函数
try
    [roughness_total, calc_time] = Roughness(rho, nodes, elements, neighbors, penalty_segs);
    fprintf('✅ 核心功能验证成功！\n');
    fprintf('总粗糙度：%.4f\n', roughness_total);
    fprintf('计算耗时：%.2f秒\n', calc_time);
    msgbox(sprintf('✅ 核心功能正常！\n总粗糙度：%.4f\n耗时：%.2f秒', roughness_total, calc_time), '验证成功');
catch ME
    fprintf('❌ 函数调用失败：%s\n', ME.message);
    errordlg(sprintf('❌ 函数调用失败：%s', ME.message), '验证失败');
end