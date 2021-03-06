/* gg_protocol.m - interface between guile and GNUstep
   Copyright (C) 1998 Free Software Foundation, Inc.

   Written by:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: September 1998

   Based on guileobjc
   	Written by:  R. Andrew McCallum <mccallum@gnu.ai.mit.edu>
   	Date: April 1995

        Including modifications by
		Masatake YAMATO (masata-y@is.aist-nara.ac.jp)

   This file is part of the GNUstep-Guile Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
   */

#include <objc/objc.h>
#include <objc/objc-api.h>
#include <objc/encoding.h>
#include <objc/Protocol.h>

#include <stdarg.h>

#include <Foundation/NSObject.h>

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSString.h>
#include <Foundation/NSData.h>

#include <string.h>		// #ifdef .. #endif

#include "private.h"

static char gstep_protocolnames_n[] = "gstep-protocolnames";

static SCM
gstep_protocolnames_fn()
{
/*
 * This implementation may be slow. I should use something 
 * like `assoc' in the elisp. - masatake
 */
  void				*enum_state = NULL;
  Class				class;
  struct objc_protocol_list	*top_list;
  SCM				answer = SCM_EOL;
  NSMutableSet			*set = nil;
  unsigned			num_of_protocol = 0;
  NSString			*nsstr = nil;
  CREATE_AUTORELEASE_POOL(arp);

  /*
   * Count
   */
  while ((class = objc_next_class(&enum_state)))
    {
      top_list = class->protocols;
      if (top_list == NULL)
	{
	  continue;
	}
      else
	{
	  int				i;
	  struct objc_protocol_list	*sub_list;

	  for (sub_list = top_list; sub_list; sub_list = sub_list->next)
	    {
	      for (i = 0; i < sub_list->count; i++)
		{
		  num_of_protocol++;
		}
	    }
	}
    }
  
  /*
   * Pick up
   */
  set = [NSMutableSet setWithCapacity: num_of_protocol];

  while ((class = objc_next_class(&enum_state)))
    {
      top_list = class -> protocols;
      if (top_list == NULL)
	{
	  continue;
	}
      else
	{
	  int i;
	  struct objc_protocol_list* sub_list;

	  for (sub_list = top_list; sub_list; sub_list = sub_list->next)
	    {
	      for (i = 0; i < sub_list->count; i++)
		{
		  nsstr = [NSString stringWithCString:
		    [sub_list->list[i] name]];
		  if ([set containsObject: nsstr] == NO)
		    {
		      [set addObject: nsstr];
		      answer = scm_cons(scm_makfrom0str([nsstr lossyCString]), 
			answer);
		    }
		  nsstr = nil;
		}
	    }
	}
    }
  // finalize
  set = nil;
  DESTROY(arp);
  return answer;
}

static char gstep_lookup_protocol_n[] = "gstep-lookup-protocol";
static Protocol * lookup_protocol_over_all_classes(char * const name);
static Protocol *
lookup_protocol_over_protocols_list(char * const name,
				    struct objc_protocol_list *protocol);

static SCM 
gstep_lookup_protocol_fn (SCM protocolname)
{
  if (SCM_NIMP(protocolname) && SCM_SYMBOLP(protocolname))
    {
      protocolname = scm_symbol_to_string(protocolname);
    }
  if (SCM_NIMP(protocolname) && SCM_STRINGP(protocolname))
    {
      char	*name;
      int	len;
      id	protocol;

      gstep_scm2str(&name, &len, &protocolname);
      protocol = (id)lookup_protocol_over_all_classes(name);
      return gstep_id2scm(protocol, NO);
    }
  else
    {
      gstep_scm_error("not a symbol or string", protocolname);
      return SCM_UNDEFINED;
    }
}

static Protocol * 
lookup_protocol_over_all_classes(char * const name)
{
  void				*enum_state = NULL;
  Class				class;
  struct objc_protocol_list	*protocols;
  Protocol			*the_protocol = NULL;

  while ((class = objc_next_class(&enum_state)))
    {
      protocols = class -> protocols;
      if (protocols == NULL)
	{
	  continue;
	}
      else
	{
	  the_protocol = lookup_protocol_over_protocols_list(name, protocols);
	  if (the_protocol)
	    break;		// Found!
	  else
	    continue;		// Not Found...go to Next class
	}
    }
  return the_protocol;
}

static Protocol *
lookup_protocol_over_protocols_list(char * const name,
				    struct objc_protocol_list * protocols)
{
  int				i;
  struct objc_protocol_list	*proto_list;

  for (proto_list = protocols; proto_list; proto_list = proto_list->next)
    {
      for (i = 0; i < proto_list->count; i++)
	{
	  if (!strcmp([proto_list->list[i] name], name))
	    {
	      return [proto_list->list[i] self];
	    }
	}
    }
  return nil; 
}



void
gstep_init_protocol()
{
  CFUN(gstep_lookup_protocol_n, 1, 0, 0, gstep_lookup_protocol_fn);
  CFUN(gstep_protocolnames_n, 0, 0, 0, gstep_protocolnames_fn);
}

