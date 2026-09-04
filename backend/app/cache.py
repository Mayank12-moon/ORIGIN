import time
from .config import settings

class TTLCache:
    def __init__(self):
        self._items = {}
    def get(self, key):
        item = self._items.get(key)
        if not item:
            return None
        expires, value = item
        if time.monotonic() >= expires:
            self._items.pop(key, None)
            return None
        return value
    def set(self, key, value):
        self._items[key] = (time.monotonic() + settings()["cache_ttl_seconds"], value)
    def clear(self):
        self._items.clear()

trace_cache = TTLCache()
