/**
 * [课程排他状态功能] 2026-02-08 冲突警告对话框
 * 在排课或调课检测到时间冲突时显示警告，让老师确认是否继续
 */

const ConflictWarningDialog = {

  /**
   * 显示冲突警告对话框（手动排课）
   * @param {Array} conflicts 冲突列表
   * @param {Object} newScheduleInfo 新排课时间信息 {startTime, endTime, stuName}
   * @returns {Promise<boolean>} 用户是否确认
   */
  show(conflicts, newScheduleInfo) {
    return this.showWithOptions(conflicts, {
      title: '时间冲突提醒',
      message: '您的排课时间与以下课程重叠：',
      hint: '集体课可以继续排课，一对一教学建议取消',
      question: '是否继续排课？',
      confirmText: '确认排课'
    }, newScheduleInfo);
  },

  /**
   * 显示调课冲突警告对话框（塞课场景）
   * @param {Array} conflicts 冲突列表
   * @param {Object} newScheduleInfo 新排课时间信息 {startTime, endTime, stuName}
   * @returns {Promise<boolean>} 用户是否确认
   */
  showRescheduleConflict(conflicts, newScheduleInfo) {
    return this.showWithOptions(conflicts, {
      title: '调课时间冲突',
      message: '您的调课目标时间与以下课程重叠：',
      hint: '集体课可以继续调课，一对一教学建议选择其他时间',
      question: '是否继续调课？',
      confirmText: '确认调课'
    }, newScheduleInfo);
  },

  /**
   * [课程排他状态功能] 2026-02-12 生成时间轴HTML
   * @param {Array} conflicts 冲突课程列表
   * @param {Object} newScheduleInfo 新排课时间信息
   * @returns {string} 时间轴HTML
   */
  generateTimelineHtml(conflicts, newScheduleInfo) {
    if (!newScheduleInfo || !conflicts || conflicts.length === 0) {
      return '';
    }

    // 解析时间为分钟数
    const parseTime = (timeStr) => {
      const parts = timeStr.split(':');
      return parseInt(parts[0]) * 60 + parseInt(parts[1]);
    };

    // 格式化时间
    const formatTime = (minutes) => {
      const h = Math.floor(minutes / 60);
      const m = minutes % 60;
      return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
    };

    // 收集所有时间点
    const newStart = parseTime(newScheduleInfo.startTime);
    const newEnd = parseTime(newScheduleInfo.endTime);
    let minTime = newStart;
    let maxTime = newEnd;

    conflicts.forEach(c => {
      const cStart = parseTime(c.startTime);
      const cEnd = parseTime(c.endTime);
      minTime = Math.min(minTime, cStart);
      maxTime = Math.max(maxTime, cEnd);
    });

    // 扩展时间范围，添加边距
    minTime = Math.floor(minTime / 30) * 30 - 30;
    maxTime = Math.ceil(maxTime / 30) * 30 + 30;
    if (minTime < 0) minTime = 0;
    if (maxTime > 24 * 60) maxTime = 24 * 60;

    const totalMinutes = maxTime - minTime;

    // 生成时间刻度（每30分钟一个刻度）
    const ticks = [];
    for (let t = minTime; t <= maxTime; t += 30) {
      const leftPercent = ((t - minTime) / totalMinutes) * 100;
      // position由CSS定义，这里只设置left；CSS中的transform:translateX(-50%)会居中对齐
      ticks.push(`<span class="timeline-tick" style="left:${leftPercent}%">${formatTime(t)}</span>`);
    }

    // 计算位置百分比
    const calcLeft = (time) => ((parseTime(time) - minTime) / totalMinutes) * 100;
    const calcWidth = (start, end) => ((parseTime(end) - parseTime(start)) / totalMinutes) * 100;

    // 生成已有课程行
    const existingRows = conflicts.map(c => {
      const left = calcLeft(c.startTime);
      const width = calcWidth(c.startTime, c.endTime);
      return `
        <div class="timeline-row">
          <div class="timeline-block existing" style="left:${left}%;width:${width}%">
            ${c.stuName} ${c.startTime}-${c.endTime}
          </div>
        </div>
      `;
    }).join('');

    // 生成新排课行
    const newLeft = calcLeft(newScheduleInfo.startTime);
    const newWidth = calcWidth(newScheduleInfo.startTime, newScheduleInfo.endTime);
    const newLabel = newScheduleInfo.stuName
      ? `${newScheduleInfo.stuName} ${newScheduleInfo.startTime}-${newScheduleInfo.endTime}`
      : `新排课 ${newScheduleInfo.startTime}-${newScheduleInfo.endTime}`;
    const newRow = `
      <div class="timeline-row">
        <div class="timeline-block new" style="left:${newLeft}%;width:${newWidth}%">
          ${newLabel}
        </div>
      </div>
    `;

    // 计算重叠区域
    let overlapHtml = '';
    conflicts.forEach(c => {
      const cStart = parseTime(c.startTime);
      const cEnd = parseTime(c.endTime);
      const overlapStart = Math.max(cStart, newStart);
      const overlapEnd = Math.min(cEnd, newEnd);
      if (overlapStart < overlapEnd) {
        const overlapLeft = ((overlapStart - minTime) / totalMinutes) * 100;
        const overlapWidth = ((overlapEnd - overlapStart) / totalMinutes) * 100;
        overlapHtml += `<div class="overlap-indicator" style="left:${overlapLeft}%;width:${overlapWidth}%"></div>`;
      }
    });

    return `
      <div class="conflict-timeline">
        <div class="timeline-title">时间轴示意图</div>
        <div class="timeline-header" style="position:relative;height:24px;">
          ${ticks.join('')}
        </div>
        <div class="timeline-track">
          ${existingRows}
          ${newRow}
          ${overlapHtml}
        </div>
        <div class="timeline-legend">
          <div class="legend-item"><span class="legend-color existing"></span>已有课程</div>
          <div class="legend-item"><span class="legend-color new"></span>新排课</div>
          <div class="legend-item"><span class="legend-color overlap"></span>重叠区域</div>
        </div>
      </div>
    `;
  },

  /**
   * 显示冲突警告对话框（通用方法）
   * @param {Array} conflicts 冲突列表
   * @param {Object} options 配置选项
   * @param {Object} newScheduleInfo 新排课时间信息
   * @returns {Promise<boolean>} 用户是否确认
   */
  showWithOptions(conflicts, options, newScheduleInfo) {
    return new Promise((resolve) => {
      // [课程排他状态功能] 2026-02-12 生成时间轴
      const timelineHtml = this.generateTimelineHtml(conflicts, newScheduleInfo);

      // 创建对话框HTML
      const dialogHtml = `
        <div class="conflict-dialog-overlay" id="conflictDialogOverlay">
          <div class="conflict-dialog">
            <div class="conflict-dialog-header">
              <span class="conflict-icon">&#9888;</span>
              <span class="conflict-title">${options.title}</span>
            </div>
            <div class="conflict-dialog-body">
              <p>${options.message}</p>
              ${timelineHtml}
              <ul class="conflict-list">
                ${conflicts.map((c, i) => `
                  <li>
                    <span class="conflict-num">${i + 1}</span>
                    <span class="conflict-info">学生：${c.stuName} &nbsp;&nbsp; 时间：${c.startTime} - ${c.endTime}</span>
                  </li>
                `).join('')}
              </ul>
              <div class="conflict-hint">
                <span class="hint-icon">&#9432;</span>
                <span>${options.hint}</span>
              </div>
              <p class="conflict-question"><strong>${options.question}</strong></p>
            </div>
            <div class="conflict-dialog-footer">
              <button class="btn-cancel" id="conflictCancelBtn">取消</button>
              <button class="btn-confirm" id="conflictConfirmBtn">${options.confirmText}</button>
            </div>
          </div>
        </div>
      `;

      // 插入DOM
      document.body.insertAdjacentHTML('beforeend', dialogHtml);

      // 绑定事件
      document.getElementById('conflictCancelBtn').onclick = () => {
        this.close();
        resolve(false);
      };

      document.getElementById('conflictConfirmBtn').onclick = () => {
        this.close();
        resolve(true);
      };
    });
  },

  /**
   * 显示同一学生冲突禁止对话框（不可继续）
   * @param {Array} conflicts 冲突列表
   * @param {Object} newScheduleInfo 新排课时间信息
   * @returns {Promise<void>}
   */
  showSameStudentConflict(conflicts, newScheduleInfo) {
    return new Promise((resolve) => {
      // [课程排他状态功能] 2026-02-12 生成时间轴
      const timelineHtml = this.generateTimelineHtml(conflicts, newScheduleInfo);

      const dialogHtml = `
        <div class="conflict-dialog-overlay" id="conflictDialogOverlay">
          <div class="conflict-dialog conflict-dialog-error">
            <div class="conflict-dialog-header conflict-header-error">
              <span class="conflict-icon">&#10060;</span>
              <span class="conflict-title">排课禁止</span>
            </div>
            <div class="conflict-dialog-body">
              <p>同一学生在该时间段已有课程安排：</p>
              ${timelineHtml}
              <ul class="conflict-list conflict-list-error">
                ${conflicts.map((c) => `
                  <li>
                    <span class="conflict-info">${c.stuName}：${c.startTime} - ${c.endTime}</span>
                  </li>
                `).join('')}
              </ul>
              <div class="conflict-hint conflict-hint-error">
                <span class="hint-icon">&#9432;</span>
                <span>同一学生不能同时上两节课，请选择其他时间</span>
              </div>
            </div>
            <div class="conflict-dialog-footer">
              <button class="btn-confirm btn-error" id="conflictCloseBtn">确定</button>
            </div>
          </div>
        </div>
      `;

      document.body.insertAdjacentHTML('beforeend', dialogHtml);

      document.getElementById('conflictCloseBtn').onclick = () => {
        this.close();
        resolve();
      };
    });
  },

  /**
   * 显示取消调课冲突禁止对话框
   * @param {string} originalTime 原时间段
   * @returns {Promise<void>}
   */
  showCancelRescheduleConflict(originalTime) {
    return new Promise((resolve) => {
      const dialogHtml = `
        <div class="conflict-dialog-overlay" id="conflictDialogOverlay">
          <div class="conflict-dialog">
            <div class="conflict-dialog-header">
              <span class="conflict-icon">&#9888;</span>
              <span class="conflict-title">无法取消调课</span>
            </div>
            <div class="conflict-dialog-body">
              <p>原时间段（${originalTime}）已安排其他学生的课程，无法恢复。</p>
              <div class="conflict-hint">
                <span class="hint-icon">&#9432;</span>
                <span>请保持当前调课状态，或选择其他时间进行调课</span>
              </div>
            </div>
            <div class="conflict-dialog-footer">
              <button class="btn-confirm" id="conflictCloseBtn">确定</button>
            </div>
          </div>
        </div>
      `;

      document.body.insertAdjacentHTML('beforeend', dialogHtml);

      document.getElementById('conflictCloseBtn').onclick = () => {
        this.close();
        resolve();
      };
    });
  },

  /**
   * 关闭对话框
   */
  close() {
    const overlay = document.getElementById('conflictDialogOverlay');
    if (overlay) {
      overlay.remove();
    }
  }
};

/**
 * 课程保存服务（带冲突检测）
 */
const LessonConflictService = {

  /**
   * 保存课程（带冲突检测）
   * @param {string} url API地址
   * @param {Object} lessonData 课程数据
   * @param {boolean} forceOverlap 是否强制保存
   * @returns {Promise<{success: boolean, hasConflict?: boolean, conflicts?: Array, message?: string}>}
   */
  async saveLesson(url, lessonData, forceOverlap = false) {
    lessonData.forceOverlap = forceOverlap;

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(lessonData)
      });

      // [Bug Fix 2026-02-11] 无论HTTP状态码如何，只要响应是JSON就解析它
      // 后端在冲突时返回HTTP 409，但响应体仍然是有效的JSON
      const contentType = response.headers.get('content-type');
      if (contentType && contentType.includes('application/json')) {
        const result = await response.json();
        return result;
      }

      // 非JSON响应，根据状态码处理
      if (response.ok) {
        return { success: true };
      } else {
        const errorText = await response.text();
        return { success: false, message: errorText };
      }
    } catch (error) {
      return { success: false, message: '网络错误：' + error.message };
    }
  },

  /**
   * 保存课程并处理冲突
   * @param {string} url API地址
   * @param {Object} lessonData 课程数据
   * @param {Object} newScheduleInfo 新排课时间信息 {startTime, endTime, stuName}
   * @param {Function} onSuccess 成功回调
   * @param {Function} onError 错误回调
   */
  async saveLessonWithConflictCheck(url, lessonData, newScheduleInfo, onSuccess, onError) {
    // 第一次调用：检测冲突
    const result = await this.saveLesson(url, lessonData, false);

    if (result.success) {
      // 保存成功
      onSuccess(result);
      return;
    }

    if (result.hasConflict) {
      // 检测到冲突
      if (result.isSameStudentConflict) {
        // 同一学生自我冲突，严格禁止
        await ConflictWarningDialog.showSameStudentConflict(result.conflicts, newScheduleInfo);
      } else {
        // 不同学生冲突，显示警告让用户确认
        const confirmed = await ConflictWarningDialog.show(result.conflicts, newScheduleInfo);

        if (confirmed) {
          // 用户确认继续，强制保存
          const forceResult = await this.saveLesson(url, lessonData, true);
          if (forceResult.success) {
            onSuccess(forceResult);
          } else {
            onError(forceResult.message || '保存失败');
          }
        }
      }
    } else {
      // 其他错误
      onError(result.message || '保存失败');
    }
  },

  /**
   * [课程排他状态功能] 2026-02-10 调课并处理冲突（塞课场景）
   * [Bug Fix 2026-02-11] 添加apiUrl参数，支持自定义API地址
   * [课程排他状态功能] 2026-02-12 添加newScheduleInfo参数，支持时间轴可视化
   * @param {string} lessonId 课程ID
   * @param {string} lsnAdjustedDate 调课目标时间（格式：yyyy-MM-dd HH:mm）
   * @param {Object} newScheduleInfo 新排课时间信息 {startTime, endTime, stuName}
   * @param {Function} onSuccess 成功回调
   * @param {Function} onError 错误回调
   * @param {string} apiUrl 可选的API地址（默认：/liu/mb_kn_lsn_updatetime）
   */
  async rescheduleLessonWithConflictCheck(lessonId, lsnAdjustedDate, newScheduleInfo, onSuccess, onError, apiUrl) {
    // 如果未提供apiUrl，使用默认值
    const url = apiUrl || '/liu/mb_kn_lsn_updatetime';

    const rescheduleData = {
      lessonId: lessonId,
      lsnAdjustedDate: lsnAdjustedDate,
      forceOverlap: false
    };

    // 第一次调用：检测冲突
    const result = await this.saveLesson(url, rescheduleData, false);

    if (result.success) {
      // 调课成功
      onSuccess(result);
      return;
    }

    if (result.hasConflict) {
      // 检测到冲突
      if (result.isSameStudentConflict) {
        // 同一学生自我冲突，严格禁止
        await ConflictWarningDialog.showSameStudentConflict(result.conflicts, newScheduleInfo);
      } else {
        // 不同学生冲突，显示警告让用户确认
        const confirmed = await ConflictWarningDialog.showRescheduleConflict(result.conflicts, newScheduleInfo);

        if (confirmed) {
          // 用户确认继续，强制调课
          rescheduleData.forceOverlap = true;
          const forceResult = await this.saveLesson(url, rescheduleData, true);
          if (forceResult.success) {
            onSuccess(forceResult);
          } else {
            onError(forceResult.message || '调课失败');
          }
        }
      }
    } else {
      // 其他错误
      onError(result.message || '调课失败');
    }
  }
};
