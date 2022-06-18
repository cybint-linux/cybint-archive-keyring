KEYRING := cybint-archive-keyring.gpg

$(KEYRING): archive-key.asc
	gpg --no-keyring --no-default-keyring --no-auto-check-trustdb \
	    --no-options --import-options import-export \
	    --import < $^ > $@

.PHONY: clean
clean:
	rm -f $(KEYRING)
