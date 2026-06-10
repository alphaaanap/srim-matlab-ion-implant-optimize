%% 离子注入多能量优化系统 - 最终优化版
% 功能：
%   1. 连续优化探索最佳能量区间
%   2. 自动寻找最佳能量个数（1-3个）
%   3. 输出可直接使用的SRIM整数能量配方

function Implantation_Optimizer_GUI()
    % 创建主窗口（稍微放大）
    fig = figure('Name', '离子注入多能量优化系统 - 连续优化版', 'Position', [50, 50, 1450, 900], ...
        'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none');
    
    % ==================== 顶部控制面板 ====================
    control_panel = uipanel('Parent', fig, 'Title', '控制面板', ...
        'Position', [0.01, 0.70, 0.98, 0.28], 'FontSize', 12, 'BackgroundColor', [0.95, 0.95, 0.95]);
    
    % ========== 第一行：路径和文件识别 ==========
    uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'SRIM数据路径:', ...
        'Position', [10, 115, 90, 25], 'HorizontalAlignment', 'right');
    path_edit = uicontrol('Parent', control_panel, 'Style', 'edit', ...
        'String', pwd, 'Position', [105, 115, 350, 25], 'HorizontalAlignment', 'left');
    
    btn_browse = uicontrol('Parent', control_panel, 'Style', 'pushbutton', ...
        'String', '浏览...', 'Position', [460, 113, 60, 28], ...
        'Callback', @(src,event) browse_folder());
    
    btn_scan = uicontrol('Parent', control_panel, 'Style', 'pushbutton', ...
        'String', '扫描文件', 'Position', [525, 113, 80, 28], ...
        'Callback', @(src,event) scan_files());
    
    % 文件列表
    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '发现文件:', ...
        'Position', [620, 115, 60, 25], 'HorizontalAlignment', 'right');
    file_listbox = uicontrol('Parent', control_panel, 'Style', 'listbox', ...
        'Position', [685, 75, 300, 65], 'Max', 10, 'Min', 0, 'Value', []);
    
    % ========== 第二行：操作按钮 ==========
    btn_import = uicontrol('Parent', control_panel, 'Style', 'pushbutton', ...
        'String', '1. 导入选中文件', 'Position', [10, 75, 110, 30], ...
        'Callback', @(src,event) import_selected_files());
    
    btn_check = uicontrol('Parent', control_panel, 'Style', 'pushbutton', ...
        'String', '2. 数据自检', 'Position', [130, 75, 90, 30], ...
        'Callback', @(src,event) check_data());
    
    btn_build = uicontrol('Parent', control_panel, 'Style', 'pushbutton', ...
        'String', '3. 构建连续模型', 'Position', [230, 75, 100, 30], ...
        'Callback', @(src,event) build_continuous_model());
    
    % 能量个数选择（增加自动选项）
    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '能量个数:', ...
        'Position', [350, 80, 60, 25], 'HorizontalAlignment', 'right');
    N_range = uicontrol('Parent', control_panel, 'Style', 'popupmenu', ...
        'String', {'自动（1-3个最优）', '1个能量', '2个能量', '3个能量'}, ...
        'Position', [415, 80, 130, 25], 'Value', 1);
    
    % ========== 目标分布类型选择 ==========
    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '分布类型:', ...
        'Position', [570, 80, 60, 25], 'HorizontalAlignment', 'right');
    target_type = uicontrol('Parent', control_panel, 'Style', 'popupmenu', ...
        'String', {'盒状分布', '斜坡分布（线性递增）', '斜坡分布（线性递减）'}, ...
        'Position', [635, 80, 140, 25], ...
        'Callback', @(src,event) toggle_target_params());
    
    % ========== 深度范围输入 ==========
    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '深度范围(Å):', ...
        'Position', [800, 80, 70, 25], 'HorizontalAlignment', 'right');
    depth_min_edit = uicontrol('Parent', control_panel, 'Style', 'edit', ...
        'String', '3000', 'Position', [875, 80, 60, 25]);
    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '~', ...
        'Position', [940, 80, 15, 25]);
    depth_max_edit = uicontrol('Parent', control_panel, 'Style', 'edit', ...
        'String', '5000', 'Position', [955, 80, 60, 25]);
    
    % ========== 盒状分布浓度输入 ==========
    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '浓度(cm⁻³):', ...
        'Position', [1040, 80, 75, 25], 'HorizontalAlignment', 'right');
    conc_edit = uicontrol('Parent', control_panel, 'Style', 'edit', ...
        'String', '2e18', 'Position', [1120, 80, 100, 25]);
    
    % ========== 斜坡分布参数（初始隐藏）==========
    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '起始浓度:', ...
        'Position', [1040, 80, 65, 25], 'HorizontalAlignment', 'right', 'Visible', 'off');
    slope_start_edit = uicontrol('Parent', control_panel, 'Style', 'edit', ...
        'String', '1e17', 'Position', [1110, 80, 80, 25], 'Visible', 'off');
    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '终止浓度:', ...
        'Position', [1200, 80, 65, 25], 'HorizontalAlignment', 'right', 'Visible', 'off');
    slope_end_edit = uicontrol('Parent', control_panel, 'Style', 'edit', ...
        'String', '2e18', 'Position', [1270, 80, 80, 25], 'Visible', 'off');
    
    % ========== 更新目标按钮 ==========
    btn_update_target = uicontrol('Parent', control_panel, 'Style', 'pushbutton', ...
        'String', '【更新目标分布】', 'Position', [1360, 78, 130, 30], ...
        'BackgroundColor', [0.7, 0.9, 0.7], 'FontWeight', 'bold', ...
        'Callback', @(src,event) update_target_preview());
    
    % ========== 第三行：优化和导出按钮 ==========
    btn_optimize = uicontrol('Parent', control_panel, 'Style', 'pushbutton', ...
        'String', '4. 自动优化', 'Position', [10, 30, 100, 32], ...
        'Callback', @(src,event) run_auto_optimization(), 'FontWeight', 'bold');
    
    btn_verify = uicontrol('Parent', control_panel, 'Style', 'pushbutton', ...
        'String', '5. SRIM验证', 'Position', [120, 30, 90, 32], ...
        'Callback', @(src,event) verify_with_srim_data(), 'Enable', 'off');
    
    btn_export = uicontrol('Parent', control_panel, 'Style', 'pushbutton', ...
        'String', '导出配方', 'Position', [220, 30, 80, 32], ...
        'Callback', @(src,event) export_recipe());
    
    % ==================== 状态栏（增大高度，确保可见）====================
    status_text = uicontrol('Parent', fig, 'Style', 'listbox', ...
        'String', {'状态：等待操作...'}, 'Position', [15, 10, 1420, 50], ...
        'BackgroundColor', [0.92, 0.92, 0.92], 'FontSize', 11);
    
    % ==================== 选项卡区域 ====================
    tab_group = uitabgroup('Parent', fig, 'Position', [0.01, 0.05, 0.98, 0.64]);
    
    % 选项卡1
    tab1 = uitab('Parent', tab_group, 'Title', '① SRIM原始数据');
    ax1 = axes('Parent', tab1, 'Position', [0.06, 0.08, 0.60, 0.85]);
    title(ax1, 'SRIM数据分布', 'FontSize', 12);
    xlabel(ax1, '深度 (μm)', 'FontSize', 10);
    ylabel(ax1, '归一化浓度', 'FontSize', 10);
    set(ax1, 'YScale', 'log');
    grid(ax1, 'on');
    hold(ax1, 'on');
    
    legend_panel1 = uipanel('Parent', tab1, 'Title', '图例', ...
        'Position', [0.72, 0.08, 0.24, 0.85]);
    legend_text1 = uicontrol('Parent', legend_panel1, 'Style', 'listbox', ...
        'String', {'等待数据导入...'}, 'Position', [10, 10, 180, 400], ...
        'FontSize', 10, 'BackgroundColor', [1, 1, 1]);
    
    % 选项卡2
    tab2 = uitab('Parent', tab_group, 'Title', '② 目标分布预览');
    ax2 = axes('Parent', tab2, 'Position', [0.06, 0.08, 0.60, 0.85]);
    title(ax2, '目标分布预览', 'FontSize', 12);
    xlabel(ax2, '深度 (μm)', 'FontSize', 10);
    ylabel(ax2, '目标浓度 (atoms/cm^3)', 'FontSize', 10);
    grid(ax2, 'on');
    hold(ax2, 'on');
    
    legend_panel2 = uipanel('Parent', tab2, 'Title', '目标参数', ...
        'Position', [0.72, 0.08, 0.24, 0.85]);
    target_info_text = uicontrol('Parent', legend_panel2, 'Style', 'listbox', ...
        'String', {'请设置参数后点击', '"【更新目标分布】" 按钮'}, ...
        'Position', [10, 10, 180, 400], 'FontSize', 10, 'BackgroundColor', [1, 1, 1]);
    
    % 选项卡3
    tab3 = uitab('Parent', tab_group, 'Title', '③ 优化结果');
    ax3 = axes('Parent', tab3, 'Position', [0.06, 0.08, 0.60, 0.85]);
    title(ax3, '优化结果对比', 'FontSize', 12);
    xlabel(ax3, '深度 (μm)', 'FontSize', 10);
    ylabel(ax3, '浓度 (atoms/cm^3)', 'FontSize', 10);
    grid(ax3, 'on');
    hold(ax3, 'on');
    
    legend_panel3 = uipanel('Parent', tab3, 'Title', '优化配方', ...
        'Position', [0.72, 0.08, 0.24, 0.85]);
    formula_text3 = uicontrol('Parent', legend_panel3, 'Style', 'listbox', ...
        'String', {'等待优化...'}, 'Position', [10, 10, 180, 400], ...
        'FontSize', 10, 'BackgroundColor', [1, 1, 1]);
    
    % 选项卡4
    tab4 = uitab('Parent', tab_group, 'Title', '④ SRIM实际结果');
    ax4 = axes('Parent', tab4, 'Position', [0.06, 0.08, 0.60, 0.85]);
    title(ax4, 'SRIM整数能量实际结果', 'FontSize', 12);
    xlabel(ax4, '深度 (μm)', 'FontSize', 10);
    ylabel(ax4, '浓度 (atoms/cm^3)', 'FontSize', 10);
    grid(ax4, 'on');
    hold(ax4, 'on');
    
    legend_panel4 = uipanel('Parent', tab4, 'Title', '最终工艺配方', ...
        'Position', [0.72, 0.08, 0.24, 0.85]);
    verify_text4 = uicontrol('Parent', legend_panel4, 'Style', 'listbox', ...
        'String', {'等待验证...'}, 'Position', [10, 10, 180, 400], ...
        'FontSize', 10, 'BackgroundColor', [1, 1, 1]);
    
    % 选项卡5
    tab5 = uitab('Parent', tab_group, 'Title', '⑤ 能量贡献分解');
    ax5 = axes('Parent', tab5, 'Position', [0.06, 0.08, 0.60, 0.85]);
    title(ax5, '各能量贡献分解', 'FontSize', 12);
    xlabel(ax5, '深度 (μm)', 'FontSize', 10);
    ylabel(ax5, '浓度 (atoms/cm^3)', 'FontSize', 10);
    grid(ax5, 'on');
    hold(ax5, 'on');
    
    legend_panel5 = uipanel('Parent', tab5, 'Title', '能量配比', ...
        'Position', [0.72, 0.08, 0.24, 0.85]);
    formula_text5 = uicontrol('Parent', legend_panel5, 'Style', 'listbox', ...
        'String', {'等待优化...'}, 'Position', [10, 10, 180, 400], ...
        'FontSize', 10, 'BackgroundColor', [1, 1, 1]);
    
    % ==================== 全局数据存储 ====================
    data = struct();
    data.energies = [];
    data.depth_all = {};
    data.conc_all = {};
    data.depth_grid = [];
    data.norm_interp_all = [];
    data.target = [];
    data.target_type = '盒状分布';
    data.model_loaded = false;
    data.best_solution = [];
    data.final_solution = [];
    data.file_list = {};
    data.continuous_predictor = [];
    
    % 界面控件句柄
    data.path_edit = path_edit;
    data.file_listbox = file_listbox;
    data.N_range = N_range;
    data.target_type_handle = target_type;
    data.depth_min_edit = depth_min_edit;
    data.depth_max_edit = depth_max_edit;
    data.conc_edit = conc_edit;
    data.slope_start_edit = slope_start_edit;
    data.slope_end_edit = slope_end_edit;
    data.btn_update_target = btn_update_target;
    data.status_text = status_text;
    data.btn_verify = btn_verify;
    data.ax1 = ax1;
    data.ax2 = ax2;
    data.ax3 = ax3;
    data.ax4 = ax4;
    data.ax5 = ax5;
    data.legend_text1 = legend_text1;
    data.target_info_text = target_info_text;
    data.formula_text3 = formula_text3;
    data.verify_text4 = verify_text4;
    data.formula_text5 = formula_text5;
    data.tab_group = tab_group;
    data.tab3 = tab3;
    data.tab4 = tab4;
    
    guidata(fig, data);
    
    % 初始化
    toggle_target_params();
    
    % ==================== 回调函数 ====================
    function browse_folder()
        data = guidata(fig);
        folder = uigetdir(pwd, '选择SRIM数据文件夹');
        if folder ~= 0
            set(data.path_edit, 'String', folder);
            scan_files();
        end
    end
    
    function scan_files()
        data = guidata(fig);
        folder = get(data.path_edit, 'String');
        
        if ~exist(folder, 'dir')
            set(data.status_text, 'String', {sprintf('文件夹不存在: %s', folder)});
            return;
        end
        
        set(data.status_text, 'String', {'正在扫描文件...'});
        drawnow;
        
        files = dir(fullfile(folder, '*.txt'));
        all_files = {};
        for i = 1:length(files)
            all_files{end+1} = files(i).name;
        end
        
        file_info = {};
        for i = 1:length(all_files)
            name = all_files{i};
            tokens = regexp(name, '\d+', 'match');
            if ~isempty(tokens)
                E = str2double(tokens{1});
                file_info{end+1} = sprintf('%d keV: %s', E, name);
            else
                file_info{end+1} = sprintf('?: %s', name);
            end
        end
        
        data.file_list = all_files;
        guidata(fig, data);
        
        set(data.file_listbox, 'String', file_info);
        set(data.status_text, 'String', {sprintf('扫描完成，发现 %d 个文件', length(all_files))});
    end
    
    function toggle_target_params()
        data = guidata(fig);
        type_val = get(data.target_type_handle, 'Value');
        
        if type_val == 1
            set(data.conc_edit, 'Visible', 'on');
            set(data.slope_start_edit, 'Visible', 'off');
            set(data.slope_end_edit, 'Visible', 'off');
            data.target_type = '盒状分布';
        else
            set(data.conc_edit, 'Visible', 'off');
            set(data.slope_start_edit, 'Visible', 'on');
            set(data.slope_end_edit, 'Visible', 'on');
            if type_val == 2
                data.target_type = '斜坡分布（线性递增）';
            else
                data.target_type = '斜坡分布（线性递减）';
            end
        end
        guidata(fig, data);
    end
    
    function import_selected_files()
        data = guidata(fig);
        folder = get(data.path_edit, 'String');
        selected = get(data.file_listbox, 'Value');
        
        if isempty(selected)
            set(data.status_text, 'String', {'请先在文件列表中选择要导入的文件'});
            return;
        end
        
        if isempty(data.file_list)
            set(data.status_text, 'String', {'请先扫描文件'});
            return;
        end
        
        set(data.status_text, 'String', {sprintf('正在导入 %d 个文件...', length(selected))});
        drawnow;
        
        energies = [];
        depth_all = {};
        conc_all = {};
        
        for i = 1:length(selected)
            idx = selected(i);
            if idx > length(data.file_list)
                continue;
            end
            filename = data.file_list{idx};
            filepath = fullfile(folder, filename);
            
            tokens = regexp(filename, '\d+', 'match');
            if isempty(tokens)
                continue;
            end
            E = str2double(tokens{1});
            
            [depth, conc] = read_srim_file(filepath);
            
            if isempty(depth)
                continue;
            end
            
            energies(end+1) = E;
            depth_all{end+1} = depth;
            conc_all{end+1} = conc;
            fprintf('✓ 导入: %d keV, %d 个数据点\n', E, length(depth));
        end
        
        if isempty(energies)
            set(data.status_text, 'String', {'错误：没有成功导入任何文件'});
            return;
        end
        
        [energies, idx] = sort(energies);
        depth_all = depth_all(idx);
        conc_all = conc_all(idx);
        
        data.energies = energies;
        data.depth_all = depth_all;
        data.conc_all = conc_all;
        guidata(fig, data);
        
        set(data.status_text, 'String', {sprintf('数据导入成功！共 %d 个能量点。', length(energies))});
        
        cla(data.ax1);
        colors = jet(length(energies));
        legend_str = {};
        for i = 1:length(energies)
            plot(data.ax1, depth_all{i}/10000, conc_all{i}, 'Color', colors(i,:), 'LineWidth', 1);
            legend_str{i} = sprintf('%.0f keV', energies(i));
        end
        title(data.ax1, 'SRIM原始数据');
        set(data.legend_text1, 'String', legend_str);
    end
    
    function [depth, conc] = read_srim_file(filepath)
        fid = fopen(filepath, 'r');
        depth = [];
        conc = [];
        
        if fid == -1
            return;
        end
        
        data_started = false;
        
        while ~feof(fid)
            line = fgetl(fid);
            if isempty(strtrim(line))
                continue;
            end
            
            if ~data_started
                if contains(line, 'DEPTH') || contains(line, 'Depth') || contains(line, '---')
                    data_started = true;
                    continue;
                end
                data_started = true;
            end
            
            if contains(line, '---') || contains(line, '===')
                continue;
            end
            
            numbers = sscanf(line, '%f');
            if length(numbers) >= 2
                depth = [depth; numbers(1)];
                conc = [conc; numbers(2)];
            end
        end
        fclose(fid);
        
        if length(depth) > 1 && any(diff(depth) < 0)
            [depth, idx] = sort(depth);
            conc = conc(idx);
        end
    end
    
    function check_data()
        data = guidata(fig);
        
        if isempty(data.energies)
            set(data.status_text, 'String', {'错误：请先导入数据。'});
            return;
        end
        
        fprintf('\n========== 数据自检结果 ==========\n');
        fprintf('能量(keV)\t数据点数\t峰值浓度\t\t峰值深度(Å)\n');
        for i = 1:length(data.energies)
            [peak, idx] = max(data.conc_all{i});
            fprintf('%d\t\t%d\t\t%.2e\t\t%.0f\n', ...
                data.energies(i), length(data.conc_all{i}), peak, data.depth_all{i}(idx));
        end
        fprintf('==================================\n');
        
        set(data.status_text, 'String', {'✓ 自检完成，请查看命令窗口输出'});
    end
    
    function build_continuous_model()
        data = guidata(fig);
        
        if isempty(data.energies)
            set(data.status_text, 'String', {'错误：请先导入数据。'});
            return;
        end
        
        set(data.status_text, 'String', {'正在构建连续预测器...'});
        drawnow;
        
        max_depth = max(cellfun(@max, data.depth_all));
        data.depth_grid = linspace(0, max_depth, 500)';
        
        data.norm_interp_all = zeros(length(data.depth_grid), length(data.energies));
        for i = 1:length(data.energies)
            data.norm_interp_all(:, i) = interp1(data.depth_all{i}, data.conc_all{i}, ...
                data.depth_grid, 'linear', 0);
        end
        
        data.continuous_predictor = @(E) continuous_predict(E, data.energies, data.norm_interp_all, data.depth_grid);
        
        data.model_loaded = true;
        guidata(fig, data);
        
        set(data.status_text, 'String', {'✓ 连续预测器构建完成！'});
        
        cla(data.ax1);
        colors = jet(length(data.energies));
        legend_str = {};
        for i = 1:length(data.energies)
            plot(data.ax1, data.depth_grid/10000, data.norm_interp_all(:,i), ...
                'Color', colors(i,:), 'LineWidth', 1);
            legend_str{i} = sprintf('%.0f keV', data.energies(i));
        end
        
        mid_E = mean(data.energies);
        pred_profile = data.continuous_predictor(mid_E);
        plot(data.ax1, data.depth_grid/10000, pred_profile, 'k--', 'LineWidth', 2);
        legend_str{end+1} = sprintf('连续预测(%.1f keV)', mid_E);
        legend(data.ax1, legend_str, 'Location', 'eastoutside');
        title(data.ax1, '连续预测器演示');
        
        fprintf('\n========== 连续预测器已构建 ==========\n');
        fprintf('能量范围: %.0f - %.0f keV\n', min(data.energies), max(data.energies));
        fprintf('=====================================\n');
    end
    
    function profile = continuous_predict(E, energies, norm_interp_all, depth_grid)
        E = E(:);
        n_E = length(E);
        n_depth = length(depth_grid);
        profile = zeros(n_depth, n_E);
        
        for i = 1:n_E
            e = E(i);
            if e <= min(energies)
                profile(:, i) = norm_interp_all(:, 1);
            elseif e >= max(energies)
                profile(:, i) = norm_interp_all(:, end);
            else
                [~, idx] = min(abs(energies - e));
                if e >= energies(idx)
                    idx1 = idx;
                    idx2 = idx + 1;
                else
                    idx1 = idx - 1;
                    idx2 = idx;
                end
                w2 = (e - energies(idx1)) / (energies(idx2) - energies(idx1));
                w1 = 1 - w2;
                profile(:, i) = w1 * norm_interp_all(:, idx1) + w2 * norm_interp_all(:, idx2);
            end
        end
    end
    
    function update_target_preview()
        data = guidata(fig);
        
        if ~data.model_loaded
            set(data.status_text, 'String', {'错误：请先构建连续模型（步骤3）'});
            return;
        end
        
        depth = data.depth_grid;
        
        depth_min = str2double(get(data.depth_min_edit, 'String'));
        depth_max = str2double(get(data.depth_max_edit, 'String'));
        
        if isnan(depth_min), depth_min = 0; end
        if isnan(depth_max), depth_max = max(depth); end
        if depth_min >= depth_max
            depth_min = 0;
            depth_max = max(depth);
            set(data.depth_min_edit, 'String', '0');
            set(data.depth_max_edit, 'String', num2str(max(depth)));
        end
        
        if strcmp(data.target_type, '盒状分布')
            conc_val = str2double(get(data.conc_edit, 'String'));
            if isnan(conc_val) || conc_val <= 0
                conc_val = 1e18;
                set(data.conc_edit, 'String', '1e18');
            end
            target = zeros(size(depth));
            target((depth >= depth_min) & (depth <= depth_max)) = conc_val;
            target_name = sprintf('盒状分布 [%d-%d Å] @ %.2e cm^{-3}', depth_min, depth_max, conc_val);
            
        elseif strcmp(data.target_type, '斜坡分布（线性递增）')
            start_conc = str2double(get(data.slope_start_edit, 'String'));
            end_conc = str2double(get(data.slope_end_edit, 'String'));
            if isnan(start_conc), start_conc = 1e17; end
            if isnan(end_conc), end_conc = 2e18; end
            
            target = zeros(size(depth));
            idx = (depth >= depth_min) & (depth <= depth_max);
            if any(idx)
                t = (depth(idx) - depth_min) / (depth_max - depth_min);
                target(idx) = start_conc + t * (end_conc - start_conc);
            end
            target_name = sprintf('斜坡递增 [%d-%d Å] %.1e→%.1e cm^{-3}', depth_min, depth_max, start_conc, end_conc);
            
        else
            start_conc = str2double(get(data.slope_start_edit, 'String'));
            end_conc = str2double(get(data.slope_end_edit, 'String'));
            if isnan(start_conc), start_conc = 2e18; end
            if isnan(end_conc), end_conc = 1e17; end
            
            target = zeros(size(depth));
            idx = (depth >= depth_min) & (depth <= depth_max);
            if any(idx)
                t = (depth(idx) - depth_min) / (depth_max - depth_min);
                target(idx) = start_conc - t * (start_conc - end_conc);
            end
            target_name = sprintf('斜坡递减 [%d-%d Å] %.1e→%.1e cm^{-3}', depth_min, depth_max, start_conc, end_conc);
        end
        
        data.target = target(:);
        guidata(fig, data);
        
        cla(data.ax2);
        plot(data.ax2, depth/10000, target, 'b-', 'LineWidth', 2);
        xlabel(data.ax2, '深度 (μm)');
        ylabel(data.ax2, '目标浓度 (atoms/cm^3)');
        title(data.ax2, target_name);
        grid(data.ax2, 'on');
        
        set(data.target_info_text, 'String', {target_name, ...
            sprintf('峰值浓度: %.2e cm^{-3}', max(target)), ...
            sprintf('总注入量: %.2e cm^{-2}', trapz(depth, target)), ...
            ' ', '点击"4. 自动优化"搜索最佳配方'});
        
        set(data.status_text, 'String', {sprintf('✓ 目标已更新: %s', target_name)});
    end
    
    % ==================== 自动优化（自动寻找最佳能量个数）====================
    function run_auto_optimization()
        data = guidata(fig);
        
        if ~data.model_loaded
            set(data.status_text, 'String', {'错误：请先构建连续模型。'});
            return;
        end
        if isempty(data.target)
            set(data.status_text, 'String', {'错误：请先点击"【更新目标分布】"按钮设置目标。'});
            return;
        end
        
        set(data.status_text, 'String', {'正在自动优化（探索1-3个能量的最佳组合）...'});
        drawnow;
        
        E_min = min(data.energies);
        E_max = max(data.energies);
        
        % 存储所有尝试的结果
        all_results = {};
        
        % 尝试1个能量
        set(data.status_text, 'String', {'自动优化：正在尝试1个能量...'});
        drawnow;
        result1 = optimize_N_energies(1, E_min, E_max, data);
        if ~isempty(result1)
            all_results{end+1} = result1;
            fprintf('  1个能量: 误差 %.2f%%\n', result1.error*100);
        end
        
        % 尝试2个能量
        set(data.status_text, 'String', {'自动优化：正在尝试2个能量...'});
        drawnow;
        result2 = optimize_N_energies(2, E_min, E_max, data);
        if ~isempty(result2)
            all_results{end+1} = result2;
            fprintf('  2个能量: 误差 %.2f%%\n', result2.error*100);
        end
        
        % 尝试3个能量
        set(data.status_text, 'String', {'自动优化：正在尝试3个能量...'});
        drawnow;
        result3 = optimize_N_energies(3, E_min, E_max, data);
        if ~isempty(result3)
            all_results{end+1} = result3;
            fprintf('  3个能量: 误差 %.2f%%\n', result3.error*100);
        end
        
        if isempty(all_results)
            set(data.status_text, 'String', {'优化失败'});
            return;
        end
        
        % 找出最佳结果（误差最小）
        best_result = all_results{1};
        for i = 2:length(all_results)
            if all_results{i}.error < best_result.error
                best_result = all_results{i};
            end
        end
        
        % 存储最佳结果
        data.best_solution = best_result;
        
        % 取整到SRIM整数能量
        final_E_list = [];
        final_D_list = [];
        
        for i = 1:length(best_result.energies)
            [~, idx] = min(abs(data.energies - best_result.energies(i)));
            int_E = data.energies(idx);
            
            found_idx = find(final_E_list == int_E, 1);
            if isempty(found_idx)
                final_E_list(end+1) = int_E;
                final_D_list(end+1) = best_result.doses(i);
            else
                final_D_list(found_idx) = final_D_list(found_idx) + best_result.doses(i);
            end
        end
        
        [final_E, sort_idx] = sort(final_E_list);
        final_D = final_D_list(sort_idx);
        
        % 计算最终方案的实际浓度分布
        final_actual = zeros(size(data.depth_grid));
        for i = 1:length(final_E)
            idx_E = find(data.energies == final_E(i), 1);
            if ~isempty(idx_E)
                final_actual = final_actual + data.norm_interp_all(:, idx_E) * final_D(i);
            end
        end
        final_error = compute_error(final_actual, data.target);
        
        data.final_solution.energies = final_E;
        data.final_solution.doses = final_D;
        data.final_solution.error = final_error;
        data.final_solution.actual_profile = final_actual;
        data.final_solution.n_energies = length(best_result.energies);
        data.final_solution.continuous_reference_E = best_result.energies;
        data.final_solution.continuous_reference_D = best_result.doses;
        
        guidata(fig, data);
        
        set(data.status_text, 'String', {sprintf('✓ 自动优化完成！最佳方案使用 %d 个能量，理论误差：%.2f%%', ...
            length(best_result.energies), best_result.error*100), ...
            sprintf('  取整后实际工艺误差：%.2f%%', final_error*100)});
        
        fprintf('\n========== 自动优化结果汇总 ==========\n');
        for i = 1:length(all_results)
            fprintf('  %d个能量: 理论误差 %.2f%%\n', length(all_results{i}.energies), all_results{i}.error*100);
        end
        fprintf('----------------------------------------\n');
        fprintf('✓ 最佳方案: %d个能量\n', length(best_result.energies));
        for i = 1:length(best_result.energies)
            fprintf('  %.1f keV 剂量 %.2e ions/cm^2 (理论)\n', best_result.energies(i), best_result.doses(i));
        end
        fprintf('理论误差: %.2f%%\n', best_result.error*100);
        
        fprintf('\n========== 最终工艺方案（SRIM整数能量）==========\n');
        for i = 1:length(final_E)
            fprintf('  %d keV 剂量 %.2e ions/cm^2\n', final_E(i), final_D(i));
        end
        fprintf('实际误差: %.2f%%\n', final_error*100);
        fprintf('================================================\n');
        
        % 更新图形
        depth = data.depth_grid;
        
        % 选项卡3：理论优化结果
        cla(data.ax3);
        plot(data.ax3, depth/10000, data.target, 'b--', 'LineWidth', 2, 'DisplayName', '目标');
        hold(data.ax3, 'on');
        plot(data.ax3, depth/10000, best_result.actual_profile, 'r-', 'LineWidth', 1.5, ...
            'DisplayName', sprintf('理论优化 (%d个能量, %.2f%%)', length(best_result.energies), best_result.error*100));
        legend(data.ax3, 'Location', 'best');
        hold(data.ax3, 'off');
        
        formula_str = {};
        for i = 1:length(best_result.energies)
            formula_str{i} = sprintf('%.1f keV: %.2e (理论)', best_result.energies(i), best_result.doses(i));
        end
        set(data.formula_text3, 'String', formula_str);
        
        % 选项卡4：SRIM实际结果
        cla(data.ax4);
        plot(data.ax4, depth/10000, data.target, 'b--', 'LineWidth', 2, 'DisplayName', '目标');
        hold(data.ax4, 'on');
        plot(data.ax4, depth/10000, final_actual, 'g-', 'LineWidth', 2, ...
            'DisplayName', sprintf('SRIM实际方案 (%.2f%%)', final_error*100));
        legend(data.ax4, 'Location', 'best');
        hold(data.ax4, 'off');
        
        final_str = {};
        final_str{1} = sprintf('【最佳方案：使用 %d 个能量】', length(final_E));
        final_str{2} = '';
        for i = 1:length(final_E)
            final_str{end+1} = sprintf('%d keV: %.2e ions/cm^2', final_E(i), final_D(i));
        end
        final_str{end+1} = '';
        final_str{end+1} = sprintf('实际误差: %.2f%%', final_error*100);
        final_str{end+1} = '';
        if final_error <= best_result.error * 1.05
            final_str{end+1} = '✓ 理论优化可靠，取整后误差损失很小';
        else
            final_str{end+1} = '⚠ 取整后误差增大较多';
        end
        set(data.verify_text4, 'String', final_str);
        
        % 选项卡5：能量贡献
        cla(data.ax5);
        colors = lines(length(final_E));
        for i = 1:length(final_E)
            idx_E = find(data.energies == final_E(i), 1);
            if ~isempty(idx_E)
                contrib = data.norm_interp_all(:, idx_E) * final_D(i);
                plot(data.ax5, depth/10000, contrib, 'Color', colors(i,:), 'LineWidth', 1.5, ...
                    'DisplayName', sprintf('%d keV', final_E(i)));
                hold(data.ax5, 'on');
            end
        end
        plot(data.ax5, depth/10000, final_actual, 'k-', 'LineWidth', 2, 'DisplayName', '总和');
        legend(data.ax5, 'Location', 'best');
        hold(data.ax5, 'off');
        
        energy_str = {};
        for i = 1:length(final_E)
            energy_str{i} = sprintf('%d keV: %.2e', final_E(i), final_D(i));
        end
        set(data.formula_text5, 'String', energy_str);
        
        set(data.btn_verify, 'Enable', 'on');
        set(data.tab_group, 'SelectedTab', data.tab3);
    end
    
    function result = optimize_N_energies(N, E_min, E_max, data)
        % 优化指定数量的能量
        result = [];
        best_error = inf;
        best_E = [];
        best_D = [];
        best_actual = [];
        
        if N == 1
            E_candidates = linspace(E_min, E_max, 80);
            for i = 1:length(E_candidates)
                E = E_candidates(i);
                norm_profile = data.continuous_predictor(E);
                norm_profile = norm_profile(:);
                target_region = find(data.target > 0);
                if length(target_region) < 10, target_region = 1:length(data.target); end
                D_opt = sum(norm_profile(target_region) .* data.target(target_region)) / sum(norm_profile(target_region).^2);
                D_opt = max(min(D_opt, 1e16), 1e10);
                actual = norm_profile * D_opt;
                error = compute_error(actual, data.target);
                if error < best_error
                    best_error = error;
                    best_E = E;
                    best_D = D_opt;
                    best_actual = actual;
                end
            end
            
        elseif N == 2
            E_candidates = linspace(E_min, E_max, 35);
            for i = 1:length(E_candidates)
                for j = i:length(E_candidates)
                    E1 = E_candidates(i);
                    E2 = E_candidates(j);
                    norm1 = data.continuous_predictor(E1);
                    norm2 = data.continuous_predictor(E2);
                    norm1 = norm1(:); norm2 = norm2(:);
                    target_region = find(data.target > 0);
                    if length(target_region) < 10, target_region = 1:length(data.target); end
                    A = [norm1(target_region), norm2(target_region)];
                    D = lsqnonneg(A, data.target(target_region));
                    D = max(min(D, 1e16), 1e10);
                    if D(1) > 0 || D(2) > 0
                        actual = norm1 * D(1) + norm2 * D(2);
                        error = compute_error(actual, data.target);
                        if error < best_error
                            best_error = error;
                            best_E = [E1, E2];
                            best_D = D;
                            best_actual = actual;
                        end
                    end
                end
            end
            
        else % N == 3
            n_random = 600;
            for iter = 1:n_random
                E = E_min + (E_max - E_min) * rand(1, 3);
                E = sort(E);
                norm1 = data.continuous_predictor(E(1));
                norm2 = data.continuous_predictor(E(2));
                norm3 = data.continuous_predictor(E(3));
                norm1 = norm1(:); norm2 = norm2(:); norm3 = norm3(:);
                target_region = find(data.target > 0);
                if length(target_region) < 10, target_region = 1:length(data.target); end
                A = [norm1(target_region), norm2(target_region), norm3(target_region)];
                D = lsqnonneg(A, data.target(target_region));
                D = max(min(D, 1e16), 1e10);
                if sum(D) > 0
                    actual = norm1 * D(1) + norm2 * D(2) + norm3 * D(3);
                    error = compute_error(actual, data.target);
                    if error < best_error
                        best_error = error;
                        best_E = E;
                        best_D = D;
                        best_actual = actual;
                    end
                end
            end
        end
        
        if ~isempty(best_E)
            result.energies = best_E;
            result.doses = best_D;
            result.error = best_error;
            result.actual_profile = best_actual;
            result.n_energies = N;
        end
    end
    
    function verify_with_srim_data()
        data = guidata(fig);
        
        if isempty(data.final_solution)
            set(data.status_text, 'String', {'请先运行优化'});
            return;
        end
        
        set(data.status_text, 'String', {'SRIM验证中...'});
        drawnow;
        
        verify_total = zeros(size(data.depth_grid));
        for i = 1:length(data.final_solution.energies)
            E = data.final_solution.energies(i);
            idx = find(data.energies == E, 1);
            if ~isempty(idx)
                verify_total = verify_total + data.norm_interp_all(:, idx) * data.final_solution.doses(i);
                fprintf('  %d keV: %.2e ions/cm^2\n', E, data.final_solution.doses(i));
            end
        end
        
        verify_error = compute_error(verify_total, data.target);
        
        cla(data.ax4);
        depth = data.depth_grid;
        plot(data.ax4, depth/10000, data.target, 'b--', 'LineWidth', 2, 'DisplayName', '目标');
        hold(data.ax4, 'on');
        plot(data.ax4, depth/10000, verify_total, 'g-', 'LineWidth', 2, ...
            'DisplayName', sprintf('SRIM验证 (%.2f%%)', verify_error*100));
        legend(data.ax4, 'Location', 'best');
        hold(data.ax4, 'off');
        
        set(data.status_text, 'String', {sprintf('SRIM验证完成！实际误差: %.2f%%', verify_error*100)});
        set(data.tab_group, 'SelectedTab', data.tab4);
    end
    
    function export_recipe()
        data = guidata(fig);
        
        if isempty(data.final_solution)
            set(data.status_text, 'String', {'请先运行优化'});
            return;
        end
        
        filename = sprintf('recipe_%s.txt', datestr(now, 'yyyymmdd_HHMMSS'));
        fid = fopen(filename, 'w');
        fprintf(fid, '离子注入工艺配方（可直接用于生产）\n');
        fprintf(fid, '生成时间: %s\n', datestr(now));
        fprintf(fid, '最佳方案使用 %d 个能量\n', data.final_solution.n_energies);
        target_str = get(data.target_info_text, 'String');
        if iscell(target_str)
            target_str = target_str{1};
        end
        fprintf(fid, '目标分布: %s\n', target_str);
        fprintf(fid, '========================\n');
        fprintf(fid, '步骤\t能量(keV)\t剂量(ions/cm^2)\n');
        for i = 1:length(data.final_solution.energies)
            fprintf(fid, '%d\t%d\t\t%.2e\n', i, data.final_solution.energies(i), data.final_solution.doses(i));
        end
        fprintf(fid, '========================\n');
        fprintf(fid, '预期误差: %.2f%%\n', data.final_solution.error*100);
        fprintf(fid, '\n理论优化参考（连续能量）：\n');
        for i = 1:length(data.final_solution.continuous_reference_E)
            fprintf(fid, '  %.1f keV: %.2e ions/cm^2\n', ...
                data.final_solution.continuous_reference_E(i), data.final_solution.continuous_reference_D(i));
        end
        fclose(fid);
        
        set(data.status_text, 'String', {sprintf('配方已保存到: %s', filename)});
        fprintf('配方已保存到: %s\n', filename);
    end
end

function err = compute_error(actual, target)
    actual = actual(:);
    target = target(:);
    max_target = max(target);
    if max_target > 0
        weights = target / max_target + 0.1;
    else
        weights = ones(size(target));
    end
    diff_sq = (actual - target).^2;
    weighted_diff = weights .* diff_sq;
    rmse = sqrt(mean(weighted_diff));
    err = rmse / max_target;
end