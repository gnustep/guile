/* gg_NSObject.m - interface between guile and GNUstep
   Copyright (C) 1998 Free Software Foundation, Inc.

   Written by:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: September 1998

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

#include "gstep_guile.h"
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSProxy.h>

/*
 *	Catagory of the 'NSObject' class for GNUstep-Guile
 */
@implementation NSObject (GNUstepGuile)

- (void) printForGuile: (SCM)port
{
  CREATE_AUTORELEASE_POOL(pool);

  if (print_for_guile == NULL)
    {
      scm_display(gh_str02scm(" string=\""), port);
      scm_display(gh_str02scm((char *)[[self description] cString]), port); 
      scm_display(gh_str02scm("\""), port);
    }
  else
    {
      print_for_guile(self, _cmd, port);
    }
  DESTROY(pool);
}

@end

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSMethodSignature.h>
#include <Foundation/NSProxy.h>
#include <objc/objc-api.h>

/*
 *	Catagory of the 'NSProxy' class for GNUstep-Guile
 *
 *	For NSProxy objects, we need to implement methodSignatureForSelector:
 *	or we can't send messasges to the proxy.  Subclasses of NSProxy should
 *	override this method anyway. 
 */

@implementation NSProxy (GNUstepGuile)

+ (NSMethodSignature*) methodSignatureForSelector: (SEL)aSelector
{
  NSMethodSignature	*sig;

  struct objc_method* mth =
    class_get_class_method(self->isa, aSelector);
  sig = mth ? [NSMethodSignature signatureWithObjCTypes:mth->method_types]
    : nil;
  return sig;
}

- (NSMethodSignature*) methodSignatureForSelector: (SEL)aSelector
{
  NSMethodSignature	*sig;

  struct objc_method* mth =
    class_get_instance_method(self->isa, aSelector);
  sig = mth ? [NSMethodSignature signatureWithObjCTypes:mth->method_types]
    : nil;
  return sig;
}

- (void) printForGuile: (SCM)port
{
  CREATE_AUTORELEASE_POOL(pool);

  if (print_for_guile == NULL)
    {
      scm_display(gh_str02scm(" string=\""), port);
      scm_display(gh_str02scm((char *)[[self description] cString]), port); 
      scm_display(gh_str02scm("\""), port);
    }
  else
    {
      print_for_guile(self, _cmd, port);
    }

  DESTROY(pool);
}

- (BOOL) respondsToSelector: (SEL)aSelector
{
  return __objc_responds_to(self, aSelector);
}

@end

