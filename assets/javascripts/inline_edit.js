(function() {
  'use strict';

  document.addEventListener('DOMContentLoaded', function() {
    initInlineEdit();
  });

  function initInlineEdit() {
    const editableCells = document.querySelectorAll('td.editable');

    editableCells.forEach(function(cell) {
      // Show edit icon on hover
      cell.addEventListener('mouseenter', function() {
        const icon = this.querySelector('.editable-icon');
        if (icon) {
          icon.style.display = 'inline';
        }
      });

      cell.addEventListener('mouseleave', function() {
        const icon = this.querySelector('.editable-icon');
        if (icon && !this.classList.contains('editing')) {
          icon.style.display = 'none';
        }
      });

      // Click to edit
      cell.addEventListener('click', function(e) {
        if (this.classList.contains('editing')) return;

        const icon = this.querySelector('.editable-icon');
        if (!icon) return; // No permission to edit

        startEditing(this);
      });
    });
  }

  function startEditing(cell) {
    cell.classList.add('editing');

    const valueSpan = cell.querySelector('.editable-value');
    const currentValue = getCleanValue(valueSpan);
    const field = cell.dataset.field;
    const type = cell.dataset.type;
    const url = cell.dataset.url;

    let input;
    if (type === 'textarea') {
      input = document.createElement('textarea');
      input.rows = 3;
      input.className = 'inline-edit-textarea';
    } else if (type === 'select') {
      input = document.createElement('select');
      input.className = 'inline-edit-select';

      // Try to get options from data attribute first (from backend)
      const optionsData = cell.dataset.options;
      if (optionsData) {
        try {
          const options = JSON.parse(optionsData);
          addOptionsFromData(input, options, currentValue);
        } catch (e) {
          // Fallback to field-based options if JSON parse fails
          addFieldOptions(input, field, currentValue);
        }
      } else {
        // Fallback to field-based options if no data attribute
        addFieldOptions(input, field, currentValue);
      }
    } else {
      input = document.createElement('input');
      input.type = 'text';
      input.className = 'inline-edit-input';
    }

    input.value = currentValue;
    input.dataset.originalValue = currentValue;

    // Create action buttons
    const actionsDiv = document.createElement('div');
    actionsDiv.className = 'inline-edit-actions';

    const saveBtn = document.createElement('button');
    saveBtn.textContent = '✓';
    saveBtn.className = 'inline-edit-save';
    saveBtn.title = 'Save';

    const cancelBtn = document.createElement('button');
    cancelBtn.textContent = '✕';
    cancelBtn.className = 'inline-edit-cancel';
    cancelBtn.title = 'Cancel';

    actionsDiv.appendChild(saveBtn);
    actionsDiv.appendChild(cancelBtn);

    // Replace content
    valueSpan.style.display = 'none';
    cell.querySelector('.editable-icon').style.display = 'none';
    cell.appendChild(input);
    cell.appendChild(actionsDiv);

    input.focus();
    if (type === 'text' || type === 'textarea') {
      input.select();
    }

    // Event handlers
    saveBtn.addEventListener('click', function(e) {
      e.stopPropagation();
      saveEdit(cell, input, url, field);
    });

    cancelBtn.addEventListener('click', function(e) {
      e.stopPropagation();
      cancelEdit(cell, input, actionsDiv);
    });

    input.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') {
        e.preventDefault();
        cancelEdit(cell, input, actionsDiv);
      } else if (e.key === 'Enter' && (type === 'text' || type === 'select' || e.ctrlKey)) {
        e.preventDefault();
        saveEdit(cell, input, url, field);
      }
    });
  }

  function saveEdit(cell, input, url, field) {
    const newValue = input.value;
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

    // Show loading state
    input.disabled = true;
    const actionsDiv = cell.querySelector('.inline-edit-actions');
    actionsDiv.style.opacity = '0.5';

    fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        field: field,
        value: newValue
      })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then(data => {
      if (data.success) {
        const valueSpan = cell.querySelector('.editable-value');
        valueSpan.innerHTML = data.formatted_value || newValue;
        finishEditing(cell, input, actionsDiv, true);

        // Show success feedback
        showSuccessFeedback(cell);
      } else {
        // Show validation error message
        const errorMsg = data.errors ? data.errors.join(', ') : 'Update failed';
        showErrorFeedback(cell, errorMsg);
        input.disabled = false;
        actionsDiv.style.opacity = '1';
      }
    })
    .catch(error => {
      console.error('Error:', error);
      showErrorFeedback(cell, 'Error saving changes: ' + error.message);
      input.disabled = false;
      actionsDiv.style.opacity = '1';
    });
  }

  function cancelEdit(cell, input, actionsDiv) {
    finishEditing(cell, input, actionsDiv, false);
  }

  function finishEditing(cell, input, actionsDiv, success) {
    input.remove();
    actionsDiv.remove();

    const valueSpan = cell.querySelector('.editable-value');
    valueSpan.style.display = '';

    cell.classList.remove('editing');
  }

  function showSuccessFeedback(cell) {
    cell.classList.add('edit-success');
    setTimeout(function() {
      cell.classList.remove('edit-success');
    }, 1500);
  }

  function showErrorFeedback(cell, message) {
    cell.classList.add('edit-error');

    // Show error message as tooltip
    const tooltip = document.createElement('div');
    tooltip.className = 'edit-error-tooltip';
    tooltip.textContent = message;
    cell.appendChild(tooltip);

    setTimeout(function() {
      cell.classList.remove('edit-error');
      tooltip.remove();
    }, 3000);
  }

  function getCleanValue(element) {
    // First, check if there's a data-value attribute with the actual value code
    // This is important for select fields where display text differs from actual value
    // (e.g., display "內部" but value is "internal")
    if (element.dataset.value) {
      return element.dataset.value;
    }

    // Remove badge markup if exists
    const badge = element.querySelector('.badge');
    if (badge) {
      return element.textContent.trim();
    }

    // Get text content and trim
    let value = element.textContent.trim();

    // Remove truncation indicator if exists
    value = value.replace(/\.\.\.$/, '');

    return value;
  }

  function addOptionsFromData(select, optionsData, currentValue) {
    // optionsData comes from backend as array of [label, value] pairs
    optionsData.forEach(function(opt) {
      const option = document.createElement('option');
      option.value = opt[1]; // value is second element
      option.textContent = opt[0]; // label is first element
      if (opt[1] === currentValue) {
        option.selected = true;
      }
      select.appendChild(option);
    });
  }

  function addFieldOptions(select, field, currentValue) {
    let options = [];

    // Define options based on field type (fallback)
    // These are hardcoded Chinese labels as fallback when backend data is unavailable
    if (field === 'location_type') {
      options = [
        { value: '', label: '-- 選擇內部/外部 --' },
        { value: 'internal', label: '內部' },
        { value: 'external', label: '外部' }
      ];
    } else if (field === 'influence_attitude') {
      options = [
        { value: '', label: '-- 選擇影響/態度 --' },
        { value: 'completely_unaware', label: '完全不覺' },
        { value: 'resistant', label: '抵制' },
        { value: 'neutral', label: '中立' },
        { value: 'supportive', label: '支持' },
        { value: 'leading', label: '領導' }
      ];
    } else {
      // Fallback for unknown fields
      options = [
        { value: '', label: '-- Select --' }
      ];
    }

    options.forEach(function(opt) {
      const option = document.createElement('option');
      option.value = opt.value;
      option.textContent = opt.label;
      if (opt.label === currentValue || opt.value === currentValue) {
        option.selected = true;
      }
      select.appendChild(option);
    });
  }

})();
