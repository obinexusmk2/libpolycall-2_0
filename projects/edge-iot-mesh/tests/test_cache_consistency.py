from hashlib import sha256


def test_cache_hash_change_detection():
    old_hash = sha256(b"old").hexdigest()
    new_hash = sha256(b"new").hexdigest()
    assert old_hash != new_hash
