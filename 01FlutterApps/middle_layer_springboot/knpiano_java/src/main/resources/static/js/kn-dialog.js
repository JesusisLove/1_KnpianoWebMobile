/**
 * [Web对话框重构] 2026-02-27 通用对话框管理
 *
 * 替代原生 alert() / confirm()，统一对话框风格。
 *
 * 使用方式：
 *   在 HTML 中引入：
 *     <link th:href="@{/css/kn-dialog.css}" rel="stylesheet">
 *     <script th:src="@{/js/kn-dialog.js}"></script>
 *
 *   代码调用：
 *     KnDialog.alert('请选择学生姓名');
 *     KnDialog.alert('请选择学生姓名', '输入提示');
 *
 *     KnDialog.error('保存失败：' + msg);
 *
 *     KnDialog.success('保存成功');        // 右上角 Toast，2.5秒后自动消失
 *
 *     const ok = await KnDialog.confirm('确定要删除吗？');
 *     if (ok) { ... }
 *
 *     KnDialog.toast('操作完成', 'success');   // 'success'|'error'|'warning'|'info'
 */

const KnDialog = {

  // ===== 私有方法：创建对话框骨架 =====

  /**
   * @private
   * @param {Object} opts
   * @param {string} opts.type       'info' | 'success' | 'error' | 'warning'
   * @param {string} opts.title      标题文字
   * @param {string} opts.icon       Emoji 图标
   * @param {string} opts.message    正文内容
   * @param {Array}  opts.buttons    按钮配置数组 [{id, text, className}]
   * @returns {string} HTML字符串
   */
  _buildHtml(opts) {
    const buttons = opts.buttons.map(btn =>
      `<button id="${btn.id}" class="kn-btn ${btn.className}">${btn.text}</button>`
    ).join('');

    return `
      <div class="kn-dialog-overlay" id="knDialogOverlay">
        <div class="kn-dialog">
          <div class="kn-dialog-header kn-dialog-header-${opts.type}">
            <span class="kn-dialog-icon">${opts.icon}</span>
            <span class="kn-dialog-title">${opts.title}</span>
          </div>
          <div class="kn-dialog-body">${opts.message}</div>
          <div class="kn-dialog-footer">${buttons}</div>
        </div>
      </div>`;
  },

  /** @private 插入并显示对话框 */
  _show(html) {
    this._close(); // 避免重叠
    document.body.insertAdjacentHTML('beforeend', html);
  },

  /** @private 关闭并移除对话框 */
  _close() {
    const el = document.getElementById('knDialogOverlay');
    if (el) el.remove();
  },

  // ===== 公开 API =====

  /**
   * 信息提示对话框（蓝色，仅 OK 按钮）
   * 替代：alert('...')
   * @param {string} message 消息内容
   * @param {string} [title='提示'] 标题
   * @returns {Promise<void>}
   */
  alert(message, title) {
    return new Promise((resolve) => {
      const html = this._buildHtml({
        type: 'info',
        title: title || '提示',
        icon: 'ℹ️',
        message: message,
        buttons: [{ id: 'knDialogOkBtn', text: '确定', className: 'kn-btn-ok' }]
      });
      this._show(html);
      document.getElementById('knDialogOkBtn').onclick = () => {
        this._close();
        resolve();
      };
    });
  },

  /**
   * 错误提示对话框（红色，仅 OK 按钮）
   * 替代：alert('保存失败：...')
   * @param {string} message 错误消息
   * @param {string} [title='错误'] 标题
   * @returns {Promise<void>}
   */
  error(message, title) {
    return new Promise((resolve) => {
      const html = this._buildHtml({
        type: 'error',
        title: title || '错误',
        icon: '❌',
        message: message,
        buttons: [{ id: 'knDialogOkBtn', text: '确定', className: 'kn-btn-ok kn-btn-ok-error' }]
      });
      this._show(html);
      document.getElementById('knDialogOkBtn').onclick = () => {
        this._close();
        resolve();
      };
    });
  },

  /**
   * 确认对话框（橙色，OK / 取消 双按钮）
   * 替代：confirm('...')
   * @param {string} message 询问内容
   * @param {string} [title='请确认'] 标题
   * @returns {Promise<boolean>} 用户点击确定 → true，取消 → false
   */
  confirm(message, title) {
    return new Promise((resolve) => {
      const html = this._buildHtml({
        type: 'warning',
        title: title || '请确认',
        icon: '⚠️',
        message: message,
        buttons: [
          { id: 'knDialogCancelBtn', text: '取消',  className: 'kn-btn-cancel' },
          { id: 'knDialogOkBtn',     text: '确定',  className: 'kn-btn-ok' }
        ]
      });
      this._show(html);
      document.getElementById('knDialogCancelBtn').onclick = () => {
        this._close();
        resolve(false);
      };
      document.getElementById('knDialogOkBtn').onclick = () => {
        this._close();
        resolve(true);
      };
    });
  },

  /**
   * 成功 Toast 通知（右上角绿色，2.5秒后自动消失，不阻塞操作）
   * 替代：alert('保存成功') + window.location.href = ...
   *
   * 典型用法：
   *   KnDialog.success('保存成功');
   *   window.location.href = listPageUrl;   // 立即跳转，toast 会在过渡中短暂显示
   *
   * @param {string} message 成功消息
   */
  success(message) {
    this.toast(message || '操作成功', 'success');
  },

  /**
   * Toast 通知（右上角浮动，自动消失）
   * @param {string} message 消息内容
   * @param {'success'|'error'|'warning'|'info'} [type='info'] 类型
   * @param {number} [duration=2500] 自动消失时间（毫秒）
   */
  toast(message, type, duration) {
    type = type || 'info';
    duration = duration || 2500;

    const icons = { success: '✅', error: '❌', warning: '⚠️', info: 'ℹ️' };

    // 确保容器存在
    let container = document.getElementById('kn-toast-container');
    if (!container) {
      container = document.createElement('div');
      container.id = 'kn-toast-container';
      document.body.appendChild(container);
    }

    // 创建 toast 元素
    const toast = document.createElement('div');
    toast.className = `kn-toast kn-toast-${type}`;
    toast.innerHTML = `
      <span class="kn-toast-icon">${icons[type] || 'ℹ️'}</span>
      <span>${message}</span>
    `;
    container.appendChild(toast);

    // 自动消失
    setTimeout(() => {
      toast.classList.add('kn-toast-fade-out');
      toast.addEventListener('animationend', () => toast.remove(), { once: true });
    }, duration);
  }

};
