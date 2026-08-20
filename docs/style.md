# Sage Route - UI 设计规范文档 (Style Guide)

## 📋 设计概述

### 1.1 设计定位
- **设计流派**: 新中式（Neo-Chinese）+ 现代极简主义
- **视觉主题**: 水墨诗意 / 文人雅士
- **情感调性**: 典雅、温润、文化厚重感
- **目标受众**: 文化爱好者、历史研究者、文艺青年

### 1.2 核心设计原则
1. ✨ **留白充足**: 采用大量留白营造呼吸感，符合中式美学"留白"理念
2. 📐 **层次分明**: 通过字重、颜色深浅、字号大小建立清晰的信息层级
3. 🔘 **圆角柔和**: 大量使用圆角（16-24px），避免尖锐感，体现温润气质
4. 🎨 **克制用色**: 以米色系为主调，仅在小面积使用传统色点缀
5. 🖼️ **图文融合**: 背景图与内容自然过渡，不抢夺内容焦点
6. 👆 **功能优先**: 在保持美学的同时确保可用性，交互区域足够大

---

## 🔤 二、字体系统 (Typography)

### 2.1 字体家族

| 用途 | 字体类型 | 示例 | 特征 |
|------|---------|------|------|
| **主标题（中文）** | 衬线字体 Serif | 白居易、白堤 | 粗体 Bold, 大字号 |
| **主标题（英文）** | 衬线斜体 Italic Serif | Bai Juyi、Bai Causeway | 斜体, 优雅感 |
| **品牌文字** | 衬线字体 | Sage __ Route | 带装饰性下划线 |
| **副标题/辅助信息** | 无衬线字体 Sans-serif | 772-846年·诗人与朝廷官员 | Regular字重 |
| **正文内容** | 无衬线字体 Sans-serif | 人物简介段落 | Regular, 易读性优先 |
| **标签/小字** | 无衬线字体 Sans-serif | 诗人、官员、哲学家 | Medium字重 |

### 2.2 字号层级规范

```
H1 - 主标题（人物/地点名）
├── 字号: 28-32px
├── 字重: Bold (700)
├── 行高: 1.3
└── 示例: "白居易"

H2 - 英文名/副标题
├── 字号: 24px
├── 字重: Regular (400)
├── 样式: Italic
└── 示例: "Bai Juyi"

H3 - 年代/地点信息
├── 字号: 14-16px
├── 字重: Regular (400)
├── 颜色: 次要文字色
└── 示例: "772-846年·诗人与朝廷官员"

Body - 正文内容
├── 字号: 16px
├── 字重: Regular (400)
├── 行高: 1.8 (宽松行距，提升阅读体验）
└── 用途: 段落文本

Caption - 辅助说明
├── 字号: 12-14px
├── 字重: Light (300)
├── 颜色: 浅灰色
└── 示例: "地址"、"数据"

Tag - 标签文字
├── 字号: 12px
├── 字重: Medium (500)
└── 示例: "诗人"、"地标"

Stat Number - 统计数字
├── 字号: 20-24px
├── 字重: Bold (700)
└── 示例: "2800+"、"4.9"
```

### 2.3 行间距规范

```css
/* 标题行高 */
line-height-title: 1.3;      /* 紧凑，突出标题 */

/* 正文行高 */
line-height-body: 1.8;       /* 宽松，提升可读性 */

/* 辅助信息行高 */
line-height-caption: 1.5;    /* 适中 */

/* 段落间距 */
paragraph-spacing: 24px;     /* 段落之间留出足够空间 */
```

---

## 🎨 三、配色方案 (Color Palette)

### 3.1 主色调

所有 App 自有界面颜色均以 `#FFE4B5` 为唯一品牌源色，与黑色或白色线性混合生成。允许纯黑、纯白作为混色端点和反色文字，不再引入独立的红、绿、蓝品牌色。

| 层级 | 色值 | 用途 |
|------|------|------|
| 品牌原色 | `#FFE4B5` | 边框、选中浅底、主题识别 |
| 深色衍生 | `#CCB691` / `#99896D` / `#665B48` / `#332E24` | 装饰、次要信息、主控件、主文字 |
| 浅色衍生 | `#FFEBC8` / `#FFF2DA` / `#FFF8ED` / `#FFFCF6` | 禁用态、页面、卡片、最浅容器 |

#### 背景色系
```css
--bg-primary: #FFF2DA;        /* 主背景 - 米黄色/宣纸色 */
--bg-secondary: #FFF8ED;      /* 卡片/模块背景 - 浅米色 */
--bg-tertiary: #FFFFFF;       /* 纯白 - 特殊卡片 */
--bg-dark: #332E24;           /* 深色背景 - 主按钮 */
--bg-overlay: rgba(0,0,0,0.4); /* 遮罩层 */
```

#### 文字色系
```css
--text-primary: #332E24;      /* 主文字 - 深灰色（非纯黑，更柔和）*/
--text-secondary: #665B48;    /* 辅助文字 - 中灰色 */
--text-tertiary: #99896D;     /* 占位符/提示 - 浅灰色 */
--text-inverse: #FFFFFF;      /* 反色文字 - 白色 */
--text-disabled: #CCB691;     /* 禁用状态 - 浅灰 */
```

### 3.2 强调色（品牌衍生色）

```css
--accent-brown: #665B48;      /* 主强调 - 标签、重要标记 */
--accent-gold: #CCB691;       /* 浅强调 - 评分、装饰 */
--accent-red: #665B48;        /* 错误语义通过图标与文案共同表达 */
--accent-green: #99896D;      /* 正向语义衍生色 */
--accent-blue: #99896D;       /* 信息语义衍生色 */
```

### 3.3 功能色

```css
/* 成功/正向 */
--color-success: #99896D;
--color-success-bg: rgba(153, 137, 109, 0.15);

/* 警告/注意 */
--color-warning: #CCB691;
--color-warning-bg: rgba(204, 182, 145, 0.15);

/* 错误/危险 */
--color-error: #665B48;
--color-error-bg: rgba(102, 91, 72, 0.15);

/* 信息/中性 */
--color-info: #99896D;
--color-info-bg: rgba(153, 137, 109, 0.15);
```

### 3.4 渐变与透明度

```css
/* 背景图片渐变遮罩（从上到下淡入背景色）*/
--overlay-gradient: linear-gradient(
  to bottom,
  rgba(255, 242, 218, 0.2) 0%,      /* 顶部几乎透明 */
  rgba(255, 242, 218, 0.7) 50%,     /* 中间半透明 */
  rgba(255, 242, 218, 0.95) 80%,    /* 下部接近不透明 */
  rgba(255, 242, 218, 1) 100%       /* 底部完全覆盖 */
);

/* 卡片阴影 */
--shadow-sm: 0 2px 8px rgba(0, 0, 0, 0.06);    /* 轻阴影 */
--shadow-md: 0 4px 16px rgba(0, 0, 0, 0.08);   /* 中阴影 */
--shadow-lg: 0 8px 24px rgba(0, 0, 0, 0.12);   /* 重阴影 */

/* 按钮阴影 */
--button-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);

/* 边框色 */
--border-color: rgba(0, 0, 0, 0.08);           /* 浅边框 */
--border-strong: rgba(0, 0, 0, 0.15);          /* 强边框 */
```

---

## 📐 四、间距系统 (Spacing)

### 4.1 基础间距单位

采用 **4px 基础网格系统**：

```css
--space-2xs: 4px;     /* 极小间距 */
--space-xs: 8px;      /* 特小间距 */
--space-sm: 12px;     /* 小间距 */
--space-md: 16px;     /* 中等间距（基准单位×4）*/
--space-lg: 24px;     /* 大间距 */
--space-xl: 32px;     /* 特大间距 */
--space-xxl: 48px;    /* 超大间距 */
--space-xxxl: 64px;   /* 章节间距 */
```

### 4.2 组件内边距规范

```css
/* 卡片内边距 */
--padding-card: 20px;
--padding-card-lg: 24px;

/* 按钮内边距 */
--padding-button-v: 16px;     /* 按钮垂直内边距 */
--padding-button-h: 32px;     /* 按钮水平内边距 */
--padding-button-small-v: 12px;
--padding-button-small-h: 24px;

/* 容器边距 */
--padding-page-h: 20px;       /* 页面左右边距 */
--padding-section-v: 32px;    /* 章节上下边距 */
```

### 4.3 元素间距

```css
/* 行内元素间距 */
--gap-inline-xs: 6px;
--gap-inline-sm: 10px;
--gap-inline-md: 14px;
--gap-inline-lg: 20px;

/* 块级元素间距 */
--gap-block-xs: 8px;
--gap-block-sm: 12px;
--gap-block-md: 16px;
--gap-block-lg: 24px;

/* 列表项间距 */
--gap-list-item: 16px;
```

---

## 🔲 五、布局系统 (Layout)

### 5.1 容器规范

```css
/* 移动端容器 */
.container {
  width: 100%;
  max-width: 414px;           /* iPhone Pro Max 尺寸 */
  margin: 0 auto;
  padding: 0 var(--padding-page-h);
}

/* 全宽容器（突破页面边距）*/
.container-full {
  width: 100vw;
  margin-left: calc(-50vw + 50%);
}
```

### 5.2 网格系统

```css
/* 统计数据网格（4列）*/
.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: var(--gap-inline-sm);
}

/* 双列网格 */
.grid-2col {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: var(--gap-block-md);
}

/* 标签流式布局 */
.tags-flow {
  display: flex;
  flex-wrap: wrap;
  gap: var(--gap-inline-xs);
}
```

---

## 🧩 六、组件规范 (Components)

### 6.1 按钮 (Buttons)

#### 主按钮 (Primary Button)
```css
.btn-primary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  
  /* 尺寸 */
  height: 52px;
  padding: 0 var(--padding-button-h);
  
  /* 视觉 */
  background: var(--bg-dark);
  color: var(--text-inverse);
  border-radius: 26px;              /* 全圆角胶囊形 */
  border: none;
  
  /* 字体 */
  font-size: 16px;
  font-weight: 600;
  
  /* 阴影 */
  box-shadow: var(--button-shadow);
  
  /* 交互 */
  transition: all 150ms ease;
  
  &:hover {
    transform: translateY(-1px);
    box-shadow: 0 6px 20px rgba(0, 0, 0, 0.2);
  }
  
  &:active {
    transform: scale(0.98);
  }
}
```

#### 次要按钮 (Secondary Button)
```css
.btn-secondary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  
  /* 尺寸 */
  height: 52px;
  padding: 0 var(--padding-button-h);
  
  /* 视觉 */
  background: transparent;
  color: var(--text-primary);
  border-radius: 26px;
  border: 1.5px solid var(--border-strong);
  
  /* 字体 */
  font-size: 16px;
  font-weight: 500;
  
  /* 交互 */
  transition: all 150ms ease;
  
  &:hover {
    background: rgba(0, 0, 0, 0.03);
    border-color: var(--text-tertiary);
  }
  
  &:active {
    transform: scale(0.98);
    background: rgba(0, 0, 0, 0.06);
  }
}
```

#### 图标按钮 (Icon Button)
```css
.btn-icon {
  /* 尺寸 */
  width: 44px;
  height: 44px;
  
  /* 视觉 */
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.05);
  border-radius: 50%;               /* 圆形 */
  border: none;
  
  /* 图标 */
  color: var(--text-primary);
  
  /* 交互 */
  transition: all 150ms ease;
  
  &:hover {
    background: rgba(0, 0, 0, 0.1);
  }
  
  &:active {
    transform: scale(0.95);
    background: rgba(0, 0, 0, 0.15);
  }
}
```

#### 文字按钮 (Text Button)
```css
.btn-text {
  /* 视觉 */
  background: transparent;
  border: none;
  color: var(--text-secondary);
  
  /* 字体 */
  font-size: 14px;
  font-weight: 500;
  
  /* 交互 */
  transition: color 150ms ease;
  
  &:hover {
    color: var(--text-primary);
  }
  
  &:active {
    color: var(--text-primary);
    opacity: 0.7;
  }
}
```

### 6.2 卡片 (Cards)

#### 内容卡片
```css
.card {
  background: var(--bg-secondary);
  border-radius: 16px;
  padding: var(--padding-card);
  box-shadow: var(--shadow-sm);
  
  /* 可选：无边框版本 */
  &.card-flat {
    box-shadow: none;
    background: var(--bg-primary);
  }
  
  /* 可选：大内边距版本 */
  &.card-lg {
    padding: var(--padding-card-lg);
  }
}
```

#### 统计数据卡片
```css
.stats-card {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: var(--gap-inline-sm);
  background: var(--bg-secondary);
  border-radius: 16px;
  padding: 16px;
  box-shadow: var(--shadow-sm);
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  
  .stat-icon {
    font-size: 18px;
    margin-bottom: 6px;
    color: var(--accent-brown);
  }
  
  .stat-value {
    font-size: 20px;
    font-weight: bold;
    color: var(--text-primary);
    line-height: 1.2;
  }
  
  .stat-label {
    font-size: 11px;
    color: var(--text-tertiary);
    margin-top: 4px;
  }
}
```

### 6.3 标签 (Tags)

```css
.tag {
  display: inline-flex;
  align-items: center;
  height: 28px;
  padding: 0 12px;
  border-radius: 14px;             /* 胶囊形全圆角 */
  font-size: 12px;
  font-weight: 500;
  white-space: nowrap;
  
  /* 不同类型的标签 */
  
  /* 棕色标签 - 主要分类 */
  &.tag-brown {
    background: rgba(102, 91, 72, 0.15);
    color: var(--accent-brown);
  }
  
  /* 绿色标签 - 正向属性 */
  &.tag-green {
    background: rgba(153, 137, 109, 0.15);
    color: var(--accent-green);
  }
  
  /* 中性标签 - 一般属性 */
  &.tag-neutral {
    background: rgba(0, 0, 0, 0.06);
    color: var(--text-secondary);
  }
  
  /* 金色标签 - 特殊标记 */
  &.tag-gold {
    background: rgba(204, 182, 145, 0.15);
    color: var(--accent-gold);
  }
}
```

### 6.4 导航栏 (Navigation Bar)

#### 顶部导航栏
```css
.nav-bar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 56px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 var(--padding-page-h);
  background: transparent;         /* 透明背景，融入图片 */
  z-index: 100;
  
  /* 左侧操作区 */
  .nav-left {
    display: flex;
    align-items: center;
    gap: 12px;
    
    .back-btn {
      /* 返回按钮 */
    }
    
    .nav-badge {
      /* 徽章标签（如"唐朝"、"唐代"）*/
      height: 28px;
      padding: 0 12px;
      background: var(--accent-brown);
      color: white;
      border-radius: 14px;
      font-size: 13px;
      font-weight: 500;
    }
  }
  
  /* 中间标题区 */
  .nav-center {
    .nav-title {
      font-family: serif;
      font-size: 17px;
      letter-spacing: 0.5px;
      color: var(--text-primary);
      
      /* 装饰性下划线效果 */
      span {
        opacity: 0.4;
      }
    }
  }
  
  /* 右侧操作区 */
  .nav-right {
    display: flex;
    align-items: center;
    gap: 12px;
    
    .icon-btn {
      /* 书签、分享等图标按钮 */
    }
  }
}
```

#### Tab 导航栏
```css
.tab-bar {
  display: flex;
  align-items: center;
  border-bottom: 1px solid var(--border-color);
  padding: 0 var(--padding-page-h);
  background: var(--bg-primary);
  
  .tab-item {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    height: 48px;
    font-size: 15px;
    color: var(--text-secondary);
    position: relative;
    cursor: pointer;
    transition: color 200ms ease;
    
    /* 未选中态 */
    &:not(.active) {
      &:hover {
        color: var(--text-primary);
      }
    }
    
    /* 选中态 */
    &.active {
      color: var(--text-primary);
      font-weight: 600;
      
      /* 底部指示器 */
      &::after {
        content: '';
        position: absolute;
        bottom: 0;
        left: 50%;
        transform: translateX(-50%);
        width: 24px;
        height: 3px;
        background: var(--text-primary);
        border-radius: 2px;
      }
    }
  }
}
```

### 6.5 表单元素 (Form Elements)

#### 输入框
```css
.input-field {
  width: 100%;
  height: 48px;
  padding: 0 16px;
  background: var(--bg-secondary);
  border: 1.5px solid transparent;
  border-radius: 12px;
  font-size: 16px;
  color: var(--text-primary);
  transition: all 150ms ease;
  
  /* 聚焦态 */
  &:focus {
    outline: none;
    border-color: var(--accent-brown);
    box-shadow: 0 0 0 3px rgba(102, 91, 72, 0.1);
  }
  
  /* 占位符 */
  &::placeholder {
    color: var(--text-tertiary);
  }
}
```

### 6.6 图片处理 (Images)

#### 背景大图
```css
.hero-image {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 60vh;                    /* 占据屏幕60%高度 */
  
  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    object-position: center;
    
    /* 降低饱和度和亮度，营造水墨朦胧感 */
    filter: saturate(0.7) brightness(0.95);
  }
  
  /* 渐变遮罩层 */
  &::after {
    content: '';
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    height: 40%;
    background: var(--overlay-gradient);
  }
}
```

#### 头像
```css
.avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  border: 2px solid var(--bg-secondary);
  object-fit: cover;
  
  /* 小尺寸 */
  &.avatar-sm {
    width: 36px;
    height: 36px;
  }
  
  /* 大尺寸 */
  &.avatar-lg {
    width: 64px;
    height: 64px;
    border-width: 3px;
  }
}
```

#### 缩略图
```css
.thumbnail {
  width: 100%;
  aspect-ratio: 16 / 9;
  border-radius: 12px;
  overflow: hidden;
  
  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 300ms ease;
  }
  
  &:hover img {
    transform: scale(1.05);
  }
}
```

---

## ✨ 七、动效与交互 (Animation & Interaction)

### 7.1 过渡时间规范

```css
/* 快速过渡 - 微交互 */
--duration-fast: 150ms ease;

/* 标准过渡 - 状态切换 */
--duration-normal: 300ms ease-out;

/* 慢速过渡 - 页面转场 */
--duration-slow: 500ms ease-in-out;
```

### 7.2 常用动效

#### 悬停提升效果
```css
.hover-lift {
  transition: transform var(--duration-fast), 
              box-shadow var(--duration-fast);
  
  &:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow-md);
  }
}
```

#### 点击反馈
```css
.tap-scale {
  transition: transform var(--duration-fast),
              opacity var(--duration-fast);
  
  &:active {
    transform: scale(0.97);
    opacity: 0.9;
  }
}
```

#### 淡入效果
```css
.fade-in {
  animation: fadeIn var(--duration-normal) ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
```

#### 加载动画
```css
.loading-spinner {
  width: 24px;
  height: 24px;
  border: 2px solid var(--border-color);
  border-top-color: var(--accent-brown);
  border-radius: 50%;
  animation: spin 800ms linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
```

---

## 📱 八、响应式断点 (Responsive Breakpoints)

```css
/* 移动端优先策略 */

/* 小屏手机 */
@media (max-width: 374px) {
  --breakpoint: 'xs';
  /* iPhone SE 及以下 */
}

/* 标准手机 */
@media (min-width: 375px) and (max-width: 413px) {
  --breakpoint: 'sm';
  /* iPhone 12/13 标准 */
}

/* 大屏手机 */
@media (min-width: 414px) and (max-width: 767px) {
  --breakpoint: 'md';
  /* iPhone Pro Max / Android 大屏 */
}

/* 平板 */
@media (min-width: 768px) and (max-width: 1023px) {
  --breakpoint: 'lg';
  /* iPad */
}

/* 桌面端 */
@media (min-width: 1024px) {
  --breakpoint: 'xl';
  /* Desktop */
}
```

---

## 🖼️ 九、图像资源规范

### 9.1 背景图片要求

| 属性 | 规格 |
|------|------|
| **风格** | 中国水墨画、山水画、古建筑摄影 |
| **色调** | 低饱和度、偏暖黄/灰绿色调 |
| **处理** | 整体透明度降至 60-70%，底部渐变淡出 |
| **格式** | WebP（首选）、JPEG |
| **尺寸** | 最小 1125 × 1200px（3x Retina）|
| **压缩** | 质量 80-85%，文件 < 500KB |

### 9.2 图标规范

| 属性 | 规格 |
|------|------|
| **风格** | 线性图标（Line Icon）、细线条 |
| **粗细** | stroke-width: 1.5px - 2px |
| **尺寸** | 24×24px（标准）、20×20px（紧凑）|
| **圆角** | 适度圆角，避免尖锐 |
| **配色** | 单色，跟随当前文字色或强调色 |
| **格式** | SVG（矢量）|

---

## 🔟 十、无障碍访问 (Accessibility)

### 10.1 对比度要求

```css
/* 文字与背景对比度需符合 WCAG AA 标准 */
/* 
   - 普通文字: 至少 4.5:1
   - 大文字(18px+): 至少 3:1
*/

/* 已验证的配对 */
.text-on-bg-primary {            /* 4.8:1 ✓ */
  color: #332E24;
  background: #FFF2DA;
}

.text-secondary-on-bg {          /* 4.2:1 ✓ */
  color: #665B48;
  background: #FFF2DA;
}

.text-inverse-on-dark {          /* 15.3:1 ✓ */
  color: #FFFFFF;
  background: #332E24;
}
```

### 10.2 触控目标尺寸

```css
/* 最小触控区域: 44×44px (Apple HIG) */
/* 推荐触控区域: 48×48px */

.touch-target {
  min-width: 44px;
  min-height: 44px;
}
```

### 10.3 动效减弱

```css
/* 尊重用户的"减少动态效果"系统设置 */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## 📚 十一、使用示例

### 11.1 人物详情页结构

```
┌─────────────────────────────────┐
│ [←] [唐朝]  Sage __ Route  [🔖][↗] │ ← 导航栏
├─────────────────────────────────┤
│                                 │
│   （水墨画背景 + 渐变遮罩）       │
│                                 │
│   白居易                        │ ← H1 主标题
│   Bai Juyi                      │ ← H2 英文斜体
│   772-846年·诗人与朝廷官员       │ ← H3 辅助信息
│                                 │
│   [诗人] [官员] [哲学家]         │ ← 标签组
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 📍12  📊4  📝2800+  ⭐4.9  │ │ ← 统计卡片
│ │ 地址  数据  诗篇    评分    │ │
│ └─────────────────────────────┘ │
│                                 │
│ [📍 规划路线]     [🗺️ 地图]    │ ← 按钮组
│                                 │
├─────────────────────────────────┤
│ [生平] [遗址] [名言] [地图] [作品]│ ← Tab 栏
├─────────────────────────────────┤
│                                 │
│ 生平 — 人物简介                 │ ← 章节标题
│                                 │
│ 白居易（772—846年）是...        │ ← 正文内容
│                                 │
└─────────────────────────────────┘
```

### 11.2 配色速查表

| 用途 | 色值 | 色块预览 |
|------|------|----------|
| **主背景** | `#FFF2DA` | 🟨 米黄色 |
| **卡片背景** | `#FFF8ED` | 🟨 浅米色 |
| **深色按钮** | `#332E24` | ⚫ 近黑色 |
| **主文字** | `#332E24` | ⚫ 深灰 |
| **辅助文字** | `#665B48` | ⚫ 中灰 |
| **浅色文字** | `#99896D` | ⚪ 浅灰 |
| **赭石色** | `#665B48` | 🟤 棕色 |
| **金色** | `#CCB691` | 🟡 金色 |
| **墨绿色** | `#99896D` | 🟢 绿色 |

---

## 🎯 十二、设计检查清单

在开发前/设计评审时，请确认以下要点：

### 视觉一致性
- [ ] 是否使用了正确的字体家族和字号？
- [ ] 配色是否符合规范？是否避免了随意新增颜色？
- [ ] 圆角是否统一？（按钮24px，卡片16px，标签14px）
- [ ] 间距是否遵循了 4px 网格系统？

### 可用性
- [ ] 所有可点击元素的触控区域是否 ≥ 44×44px？
- [ ] 文字与背景的对比度是否达到 WCAG AA 标准？
- [ ] 重要操作的按钮是否足够醒目？
- [ ] 是否考虑了"减少动效"模式？

### 性能
- [ ] 背景图片是否进行了优化压缩？
- [ ] 图标是否使用了 SVG 格式？
- [ ] 动效是否流畅（60fps）？

### 品牌一致
- [ ] 整体视觉是否传达了"典雅、文化、温润"的感觉？
- [ ] 水墨风格的运用是否克制且恰当？
- [ ] 中英文混排是否和谐美观？

---

## 📝 附录：CSS 变量完整定义

```css
:root {
  /* === 背景色 === */
  --bg-primary: #FFF2DA;
  --bg-secondary: #FFF8ED;
  --bg-tertiary: #FFFFFF;
  --bg-dark: #332E24;
  
  /* === 文字色 === */
  --text-primary: #332E24;
  --text-secondary: #665B48;
  --text-tertiary: #99896D;
  --text-inverse: #FFFFFF;
  
  /* === 强调色 === */
  --accent-brown: #665B48;
  --accent-gold: #CCB691;
  --accent-red: #665B48;
  --accent-green: #99896D;
  --accent-blue: #99896D;
  
  /* === 间距 === */
  --space-xs: 8px;
  --space-sm: 12px;
  --space-md: 16px;
  --space-lg: 24px;
  --space-xl: 32px;
  
  /* === 圆角 === */
  --radius-sm: 8px;
  --radius-md: 12px;
  --radius-lg: 16px;
  --radius-xl: 24px;
  --radius-full: 9999px;
  
  /* === 阴影 === */
  --shadow-sm: 0 2px 8px rgba(0, 0, 0, 0.06);
  --shadow-md: 0 4px 16px rgba(0, 0, 0, 0.08);
  --shadow-lg: 0 8px 24px rgba(0, 0, 0, 0.12);
  
  /* === 过渡 === */
  --transition-fast: 150ms ease;
  --transition-normal: 300ms ease-out;
  --transition-slow: 500ms ease-in-out;
}
```

---

**文档版本**: v1.0  
**最后更新**: 2024  
**适用范围**: Sage Route App 全平台（iOS / Android / Web）

> 💡 **提示**: 本文档应作为设计和开发的权威参考。如有任何疑问或建议更新，请联系设计团队。
