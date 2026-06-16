if(CONFIG_KEYB_VIEWER)
  zephyr_library()
  zephyr_library_sources(src/keyb_viewer.c)
endif()
