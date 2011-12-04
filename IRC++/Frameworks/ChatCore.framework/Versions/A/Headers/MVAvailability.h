#undef ENABLE
#define ENABLE(CHAT_FEATURE) (defined(ENABLE_##CHAT_FEATURE) && ENABLE_##CHAT_FEATURE)
#define USE(CHAT_FEATURE) (defined(USE_##CHAT_FEATURE) && USE_##CHAT_FEATURE)

#ifndef ENABLE_AUTO_PORT_MAPPING
#define ENABLE_AUTO_PORT_MAPPING 1
#endif

#ifndef ENABLE_SCRIPTING
#define ENABLE_SCRIPTING 1
#endif

#ifndef ENABLE_PLUGINS
#define ENABLE_PLUGINS 1
#endif

#ifndef ENABLE_IRC
#define ENABLE_IRC 1
#endif

#ifdef ENABLE_SILC
#undef ENABLE_SILC
#endif

#ifdef ENABLE_ICB
#undef ENABLE_ICB
#endif

#ifndef ENABLE_XMPP
#undef ENABLE_XMPP
#endif
