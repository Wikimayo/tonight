const maxAiRequestsPerDay = 100;

let currentDate = getTodayKey();
let requestCount = 0;

function canUseAi() {
  resetIfDayChanged();
  return requestCount < maxAiRequestsPerDay;
}

function registerAiUse() {
  resetIfDayChanged();
  requestCount += 1;
  return getUsageStatus();
}

function getUsageStatus() {
  resetIfDayChanged();

  return {
    currentDate,
    requestCount,
    maxAiRequestsPerDay,
    remaining: Math.max(maxAiRequestsPerDay - requestCount, 0),
  };
}

function resetIfDayChanged() {
  const today = getTodayKey();

  if (today !== currentDate) {
    currentDate = today;
    requestCount = 0;
  }
}

function getTodayKey() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');

  return `${year}-${month}-${day}`;
}

module.exports = {
  canUseAi,
  registerAiUse,
  getUsageStatus,
};
